import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import '../constants/app_constants.dart';
import '../models/connection_state.dart'
    show ConnectionStatus, AirPlayConnectionState;
import 'mdns_service.dart';
import 'network_monitor_service.dart';
import 'rtsp_service.dart';
import 'performance_monitor_service.dart';
import 'audio_video_sync_service.dart';
import 'video_decoder_service.dart';
import 'audio_decoder_service.dart';
import 'performance_optimization_service.dart';
import 'settings_service.dart';
import 'logger_service.dart';

class AirPlayService {
  HttpServer? _httpServer;
  final MdnsService _mdnsService = MdnsService();
  final NetworkMonitorService _networkMonitor = NetworkMonitorService();
  final RtspService _rtspService = RtspService();
  final PerformanceMonitorService _performanceMonitor =
      PerformanceMonitorService();
  final AudioVideoSyncService _syncService = AudioVideoSyncService();
  final VideoDecoderService _decoderService = VideoDecoderService();
  final AudioDecoderService _audioDecoderService = AudioDecoderService();
  PerformanceOptimizationService? _optimizationService;
  StreamSubscription? _settingsSubscription;

  // 服务状态管理
  bool _isStarting = false;
  bool _isStopping = false;
  bool _isRunning = false;
  StreamSubscription? _rtspSubscription;

  final StreamController<AirPlayConnectionState> _stateController =
      StreamController<AirPlayConnectionState>.broadcast();

  Stream<AirPlayConnectionState> get stateStream => _stateController.stream;
  AirPlayConnectionState _currentState = const AirPlayConnectionState();

  AirPlayConnectionState get currentState => _currentState;
  bool get isRunning => _isRunning;
  bool get isStarting => _isStarting;
  bool get isStopping => _isStopping;

  NetworkMonitorService get networkMonitor => _networkMonitor;
  RtspService get rtspService => _rtspService;
  PerformanceMonitorService get performanceMonitor => _performanceMonitor;
  AudioVideoSyncService get syncService => _syncService;
  VideoDecoderService get decoderService => _decoderService;
  AudioDecoderService get audioDecoderService => _audioDecoderService;
  PerformanceOptimizationService? get optimizationService =>
      _optimizationService;

  void _updateState(AirPlayConnectionState newState) {
    _currentState = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  Future<void> startService() async {
    // 防止重复启动
    if (_isStarting || _isRunning) {
      Log.w('AirPlayService', '服务正在启动或已运行，跳过启动请求');
      return;
    }

    _isStarting = true;

    try {
      Log.i('AirPlayService', '开始启动AirPlay服务');
      _updateState(
          _currentState.copyWith(status: ConnectionStatus.discovering));

      // 初始化设置服务
      Log.d('AirPlayService', '初始化设置服务');
      await settingsService.initialize();

      // 监听设置变化
      _settingsSubscription =
          settingsService.settingsStream.listen(_onSettingsChanged);

      // 初始化优化服务
      Log.d('AirPlayService', '初始化性能优化服务');
      _optimizationService =
          PerformanceOptimizationService(_performanceMonitor);
      _optimizationService?.setDecoderService(_decoderService);

      // 启动网络监控
      Log.d('AirPlayService', '启动网络监控服务');
      await _networkMonitor.startMonitoring();

      // 启动性能监控
      Log.d('AirPlayService', '启动性能监控服务');
      await _performanceMonitor.startMonitoring();

      // 等待网络连接
      if (!_networkMonitor.currentNetworkInfo.isConnected) {
        Log.w('AirPlayService', '网络未连接，等待网络连接');
        await _waitForNetworkConnection();
      }
      Log.i('AirPlayService',
          '网络连接正常: ${_networkMonitor.currentNetworkInfo.ipAddress}');

      // 初始化视频解码器
      Log.d('AirPlayService', '初始化视频解码器');
      await _decoderService.initialize();
      _decoderService.setSyncService(_syncService);

      // 初始化音频解码器
      Log.d('AirPlayService', '初始化音频解码器');
      await _audioDecoderService.initialize();
      _audioDecoderService.setSyncService(_syncService);

      // 启动HTTP服务器
      Log.d('AirPlayService', '启动HTTP服务器');
      await _startHttpServer();

      // 启动RTSP服务器
      Log.d('AirPlayService', '启动RTSP服务器');
      await _rtspService.startRtspServer();

      // 连接RTSP服务与解码器
      _rtspService.setVideoDecoderService(_decoderService);
      _rtspService.setAudioDecoderService(_audioDecoderService);

      // 启动mDNS广播
      Log.d('AirPlayService', '启动mDNS广播服务');
      await _mdnsService.startAdvertising();

      // 监听RTSP消息
      _rtspSubscription = _rtspService.messageStream.listen(_handleRtspMessage);

      // 启动音视频同步服务
      Log.d('AirPlayService', '启动音视频同步服务');
      _syncService.startSync();

      // 启动性能优化服务
      _optimizationService?.startOptimization();

      _isRunning = true;
      _updateState(
          _currentState.copyWith(status: ConnectionStatus.disconnected));
      Log.i('AirPlayService', 'AirPlay服务启动完成，等待设备连接');
    } catch (e, stackTrace) {
      Log.e('AirPlayService', '启动服务失败', e, stackTrace);

      // 启动失败时清理已初始化的资源
      await _cleanupOnFailure();

      _updateState(_currentState.copyWith(
          status: ConnectionStatus.error, errorMessage: '启动服务失败: $e'));
      rethrow;
    } finally {
      _isStarting = false;
    }
  }

  Future<void> _cleanupOnFailure() async {
    Log.w('AirPlayService', '服务启动失败，清理资源');

    try {
      // 取消RTSP监听
      await _rtspSubscription?.cancel();
      _rtspSubscription = null;

      // 停止各种服务（忽略错误）
      await _mdnsService.stopAdvertising().catchError((_) {});
      await _rtspService.stopRtspServer().catchError((_) {});
      await _httpServer?.close().catchError((_) {});
      await _networkMonitor.stopMonitoring().catchError((_) {});
      await _performanceMonitor.stopMonitoring().catchError((_) {});

      _syncService.stopSync();
      _optimizationService?.stopOptimization();

      await _decoderService.dispose().catchError((_) {});
      await _audioDecoderService.dispose().catchError((_) {});

      _httpServer = null;
      _optimizationService = null;
      _isRunning = false;
    } catch (e) {
      Log.e('AirPlayService', '清理资源时出错', e);
    }
  }

  Future<void> _startHttpServer() async {
    final router = Router();

    // AirPlay设备信息接口
    router.get('/info', (shelf.Request request) {
      // 获取与mDNS服务一致的设备信息
      final localIP =
          _networkMonitor.currentNetworkInfo.ipAddress ?? '192.168.1.100';
      final deviceId = _generateDeviceId(localIP);
      final piId = _generatePiId(localIP);

      final deviceInfo = {
        'name': AppConstants.deviceName,
        'model': 'OPPO,Pad4Pro',
        'srcvers': '377.20.1', // 更新到较新版本，提高兼容性
        'pi': piId,
        'vv': 2,
        'features': '0x5A7FFFF7,0x1E', // 完整的AirPlay功能支持
        'flags': '0x244', // 与mDNS保持一致
        'statusflags': '0x44',
        'deviceid': deviceId,
        'displays': AppConstants.airplayFeatures['displays'],
        // 添加更多AirPlay兼容性字段
        'protovers': '1.0',
        'pw': '0', // 不需要密码
        'da': 'true', // 设备身份验证
        'sv': 'false', // 不是Apple设备
        'pk': _generatePublicKey(), // 伪造的公钥
        'txtvers': '1',
        // 添加Mac兼容性关键字段
        'acl': '0', // 访问控制列表
        'btaddr': '00:00:00:00:00:00', // 蓝牙地址（伪造）
        'gcgl': '1', // Game Center
        'gid': '00000000-0000-0000-0000-000000000000', // 游戏ID
        'igl': '1', // iCloud游戏库
        'psi': '00000000-0000-0000-0000-000000000000', // 程序会话ID
      };

      return shelf.Response.ok(
        jsonEncode(deviceInfo),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // 处理配对设置请求
    router.post('/pair-setup', (shelf.Request request) async {
      Log.i('AirPlayService', '收到pair-setup请求');
      _updateState(_currentState.copyWith(status: ConnectionStatus.connecting));

      // 无PIN码模式的配对响应
      final response = {
        'status': 0,
        'sessionID': '12345678-1234-1234-1234-123456789ABC'
      };

      return shelf.Response.ok(
        jsonEncode(response),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // 处理配对验证请求
    router.post('/pair-verify', (shelf.Request request) async {
      Log.i('AirPlayService', '收到pair-verify请求');
      
      // 简化的验证响应（跳过加密）
      final response = {
        'status': 0,
        'sessionID': '12345678-1234-1234-1234-123456789ABC'
      };

      return shelf.Response.ok(
        jsonEncode(response),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // 处理播放请求
    router.post('/play', (shelf.Request request) async {
      Log.i('AirPlayService', '收到play请求');
      
      // 切换到streaming状态，触发UI跳转到视频页面
      _updateState(_currentState.copyWith(
        status: ConnectionStatus.streaming,
        connectedDeviceName: 'Mac设备',
      ));
      
      Log.i('AirPlayService', '已切换到streaming状态，UI应该跳转到视频页面');
      
      final response = {'status': 0};
      return shelf.Response.ok(
        jsonEncode(response),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // 处理停止请求
    router.post('/stop', (shelf.Request request) async {
      Log.i('AirPlayService', '收到stop请求');
      
      _updateState(_currentState.copyWith(status: ConnectionStatus.disconnected));
      
      final response = {'status': 0};
      return shelf.Response.ok(
        jsonEncode(response),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // 处理音量控制
    router.post('/volume', (shelf.Request request) async {
      final body = await request.readAsString();
      Log.i('AirPlayService', '收到volume请求: $body');
      
      final response = {'status': 0};
      return shelf.Response.ok(
        jsonEncode(response),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // 处理属性设置
    router.put('/property', (shelf.Request request) async {
      final body = await request.readAsString();
      Log.i('AirPlayService', '收到property请求: $body');
      
      final response = {'status': 0};
      return shelf.Response.ok(
        jsonEncode(response),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // 处理AirPlay 2.0的关键端点
    router.post('/fp-setup', (shelf.Request request) async {
      Log.i('AirPlayService', '收到fp-setup请求 (FairPlay DRM设置)');
      
      // 跳过FairPlay DRM，返回成功
      final response = {
        'status': 0,
        'type': 'no-fairplay'
      };
      
      return shelf.Response.ok(
        jsonEncode(response),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // 处理AirPlay连接设置
    router.post('/setup', (shelf.Request request) async {
      Log.i('AirPlayService', '收到setup请求');
      
      // 更新连接状态为已连接，准备接收流媒体
      _updateState(_currentState.copyWith(
        status: ConnectionStatus.connected,
        connectedDeviceName: 'Mac设备',
      ));
      
      final response = {
        'status': 0,
        'sessionUUID': '12345678-1234-1234-1234-123456789ABC'
      };
      
      return shelf.Response.ok(
        jsonEncode(response),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // 处理拆除连接
    router.post('/teardown', (shelf.Request request) async {
      Log.i('AirPlayService', '收到teardown请求');
      
      _updateState(_currentState.copyWith(status: ConnectionStatus.disconnected));
      
      final response = {'status': 0};
      return shelf.Response.ok(
        jsonEncode(response),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // 处理OPTIONS请求（用于CORS预检）
    router.options('/<path|.*>', (shelf.Request request, String path) async {
      Log.d('AirPlayService', '收到OPTIONS预检请求: /$path');
      return shelf.Response.ok(
        '',
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Apple-*',
          'Access-Control-Max-Age': '86400',
        },
      );
    });

    // 处理反向HTTP连接（Mac镜像显示需要）
    router.post('/reverse', (shelf.Request request) async {
      Log.i('AirPlayService', '收到reverse HTTP连接请求');
      
      final response = {
        'status': 0,
        'streams': [
          {
            'type': 110, // 视频流
            'streamConnectionID': 1,
          }
        ]
      };
      
      return shelf.Response.ok(
        jsonEncode(response),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // RTSP流媒体端点
    router.post('/stream', (shelf.Request request) async {
      final clientIP = request.headers['x-forwarded-for'] ??
          request.headers['x-real-ip'] ??
          'Unknown';

      Log.i('AirPlayService', '收到stream请求，客户端IP: $clientIP');

      _updateState(_currentState.copyWith(
          status: ConnectionStatus.streaming,
          connectedDeviceIP: clientIP,
          connectedDeviceName: 'Mac设备'));

      return shelf.Response.ok('Stream started');
    });

    // AirPlay 服务器状态端点
    router.get('/server-info', (shelf.Request request) {
      final serverInfo = {
        'deviceName': AppConstants.deviceName,
        'model': 'OPPO,Pad4Pro',
        'macAddress': _generateDeviceId(
            _networkMonitor.currentNetworkInfo.ipAddress ?? '192.168.1.100'),
        'features': '0x5A7FFFF7,0x1E',
        'statusFlags': '0x44',
        'protocolVersion': '1.0',
        'sourceVersion': '366.0',
      };

      return shelf.Response.ok(
        jsonEncode(serverInfo),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // AirPlay 播放状态端点
    router.get('/playback-info', (shelf.Request request) {
      final playbackInfo = {
        'duration': 0.0,
        'loadedTimeRanges': [],
        'playbackBufferEmpty': true,
        'playbackBufferFull': false,
        'playbackLikelyToKeepUp': true,
        'position': 0.0,
        'rate': 1.0,
        'readyToPlay': true,
        'seekableTimeRanges': [],
      };

      return shelf.Response.ok(
        jsonEncode(playbackInfo),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // 添加CORS中间件，支持跨域请求
    shelf.Middleware corsMiddleware() {
      return (shelf.Handler handler) {
        return (shelf.Request request) async {
          if (request.method == 'OPTIONS') {
            return shelf.Response.ok(
              '',
              headers: {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization',
                'Access-Control-Max-Age': '86400',
              },
            );
          }

          final response = await handler(request);
          return response.change(headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization',
            ...response.headers,
          });
        };
      };
    }

    final handler = const shelf.Pipeline()
        .addMiddleware(corsMiddleware())
        .addMiddleware(shelf.logRequests())
        .addHandler(router.call);

    _httpServer = await shelf_io.serve(
      handler,
      InternetAddress.anyIPv4,
      AppConstants.airplayPort,
    );

    Log.i('AirPlayService', 'HTTP服务器启动在端口: ${AppConstants.airplayPort}');
  }

  Future<void> _waitForNetworkConnection() async {
    final completer = Completer<void>();
    late StreamSubscription subscription;

    subscription = _networkMonitor.networkStream.listen((networkInfo) {
      if (networkInfo.isConnected && !completer.isCompleted) {
        subscription.cancel();
        completer.complete();
      }
    });

    // 最多等待30秒
    await completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        subscription.cancel();
        throw TimeoutException('等待网络连接超时', const Duration(seconds: 30));
      },
    );
  }

  Future<void> stopService() async {
    // 防止重复停止
    if (_isStopping || !_isRunning) {
      Log.w('AirPlayService', '服务正在停止或未运行，跳过停止请求');
      return;
    }

    _isStopping = true;

    try {
      Log.i('AirPlayService', '开始停止AirPlay服务');
      _updateState(
          _currentState.copyWith(status: ConnectionStatus.disconnected));

      // 有序停止各种服务
      await _stopServicesSequentially();

      _isRunning = false;
      _updateState(
          const AirPlayConnectionState(status: ConnectionStatus.disconnected));
      Log.i('AirPlayService', 'AirPlay服务已完全停止');
    } catch (e, stackTrace) {
      Log.e('AirPlayService', '停止服务时出错', e, stackTrace);
    } finally {
      _isStopping = false;
    }
  }

  Future<void> _stopServicesSequentially() async {
    final stopTasks = <Future<void>>[];

    try {
      // 1. 首先停止流媒体相关服务
      Log.d('AirPlayService', '停止流媒体服务');
      if (_currentState.status == ConnectionStatus.streaming) {
        await _decoderService.stopDecoding().catchError((e) {
          Log.w('AirPlayService', '停止视频解码失败: $e');
        });
        await _audioDecoderService.stopDecoding().catchError((e) {
          Log.w('AirPlayService', '停止音频解码失败: $e');
        });
      }

      // 2. 停止同步和优化服务
      Log.d('AirPlayService', '停止同步和优化服务');
      _syncService.stopSync();
      _optimizationService?.stopOptimization();

      // 3. 取消监听
      Log.d('AirPlayService', '取消RTSP监听');
      await _rtspSubscription?.cancel();
      _rtspSubscription = null;

      // 4. 并行停止网络相关服务
      Log.d('AirPlayService', '停止网络服务');
      stopTasks.addAll([
        _mdnsService.stopAdvertising().catchError((e) {
          Log.w('AirPlayService', '停止mDNS广播失败: $e');
        }),
        _rtspService.stopRtspServer().catchError((e) {
          Log.w('AirPlayService', '停止RTSP服务失败: $e');
        }),
        _httpServer?.close().then((_) {
              _httpServer = null;
            }).catchError((e) {
              Log.w('AirPlayService', '关闭HTTP服务器失败: $e');
            }) ??
            Future.value(),
      ]);

      // 5. 并行停止监控服务
      Log.d('AirPlayService', '停止监控服务');
      stopTasks.addAll([
        _networkMonitor.stopMonitoring().catchError((e) {
          Log.w('AirPlayService', '停止网络监控失败: $e');
        }),
        _performanceMonitor.stopMonitoring().catchError((e) {
          Log.w('AirPlayService', '停止性能监控失败: $e');
        }),
      ]);

      // 6. 最后清理解码器
      Log.d('AirPlayService', '清理解码器');
      stopTasks.addAll([
        _decoderService.dispose().catchError((e) {
          Log.w('AirPlayService', '清理视频解码器失败: $e');
        }),
        _audioDecoderService.dispose().catchError((e) {
          Log.w('AirPlayService', '清理音频解码器失败: $e');
        }),
      ]);

      // 等待所有任务完成（最多30秒）
      await Future.wait(stopTasks).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Log.w('AirPlayService', '停止服务超时，但继续完成');
          return <void>[];
        },
      );

      // 最终清理
      _optimizationService = null;
    } catch (e, stackTrace) {
      Log.e('AirPlayService', '停止服务序列出错', e, stackTrace);
      rethrow;
    }
  }

  void _handleRtspMessage(RtspMessage message) async {
    Log.i('AirPlayService', '收到RTSP消息: ${message.method} ${message.uri}');

    switch (message.method) {
      case 'PLAY':
        Log.i('AirPlayService', '开始播放流媒体');
        // 开始播放，切换到streaming状态
        _updateState(_currentState.copyWith(
          status: ConnectionStatus.streaming,
          connectedDeviceName: 'Mac设备',
        ));
        // 重置音视频同步状态
        _syncService.resetSync();
        // 开始视频解码
        await _decoderService.startDecoding();
        // 开始音频解码
        await _audioDecoderService.startDecoding();
        // 切换到性能优先模式
        _optimizationService
            ?.setOptimizationLevel(OptimizationLevel.performance);
        Log.i('AirPlayService', '流媒体播放已启动');
        break;
      case 'TEARDOWN':
        Log.i('AirPlayService', '停止流媒体播放');
        // 停止播放，返回connected状态
        _updateState(_currentState.copyWith(
          status: ConnectionStatus.connected,
        ));
        // 停止音视频同步
        _syncService.resetSync();
        // 停止视频解码
        await _decoderService.stopDecoding();
        // 停止音频解码
        await _audioDecoderService.stopDecoding();
        // 切换回平衡模式
        _optimizationService?.setOptimizationLevel(OptimizationLevel.balanced);
        Log.i('AirPlayService', '流媒体播放已停止');
        break;
    }
  }

  Future<void> dispose() async {
    Log.i('AirPlayService', '开始清理AirPlay服务资源');

    try {
      // 先确保服务已停止
      if (_isRunning) {
        await stopService();
      }

      // 取消任何剩余的订阅
      await _rtspSubscription?.cancel();
      _rtspSubscription = null;

      // 取消设置监听
      await _settingsSubscription?.cancel();
      _settingsSubscription = null;

      // 关闭状态控制器
      if (!_stateController.isClosed) {
        await _stateController.close();
      }

      // 清理所有服务
      try {
        _mdnsService.dispose();
        _networkMonitor.dispose();
        _rtspService.dispose();
        _performanceMonitor.dispose();
        _syncService.dispose();
        _optimizationService?.dispose();
        await _decoderService.dispose();
        await _audioDecoderService.dispose();
      } catch (e) {
        Log.w('AirPlayService', '清理服务时部分资源清理失败: $e');
      }

      // 重置状态
      _isStarting = false;
      _isStopping = false;
      _isRunning = false;
      _optimizationService = null;
      _httpServer = null;

      Log.i('AirPlayService', 'AirPlay服务资源清理完成');
    } catch (e, stackTrace) {
      Log.e('AirPlayService', '清理服务资源时出错', e, stackTrace);
    }
  }

  String _generateDeviceId(String localIP) {
    // 基于设备名和IP生成一致的设备ID (与mDNS服务保持一致)
    final base = '${AppConstants.deviceName}$localIP';
    final hash = base.hashCode.abs().toRadixString(16).padLeft(12, '0');
    return '${hash.substring(0, 2)}:${hash.substring(2, 4)}:${hash.substring(4, 6)}:${hash.substring(6, 8)}:${hash.substring(8, 10)}:${hash.substring(10, 12)}';
  }

  String _generatePiId(String localIP) {
    // 生成UUID格式的PI ID (与mDNS服务保持一致)
    final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    final random = localIP.hashCode.abs().toRadixString(16).padLeft(8, '0');
    return '${timestamp.substring(0, 8)}-${random.substring(0, 4)}-4000-8000-${timestamp.substring(8)}${random.substring(4)}';
  }

  String _generatePublicKey() {
    // 生成伪造的Ed25519公钥（32字节，Base64编码）
    // 实际的AirPlay需要真实的密钥对，这里为了兼容性提供伪造的
    const fakeKey = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
    return fakeKey;
  }

  // ==================== 设置管理 ====================

  void _onSettingsChanged(AirPlaySettings settings) async {
    Log.d('AirPlayService', '设置已更新，应用新配置');

    try {
      // 应用性能设置
      _applyPerformanceSettings(settings);

      // 应用视频设置
      _applyVideoSettings(settings);

      // 应用音频设置
      _applyAudioSettings(settings);

      // 应用同步设置
      _applySyncSettings(settings);

      // 应用网络设置
      _applyNetworkSettings(settings);

      // 应用调试设置
      _applyDebugSettings(settings);
    } catch (e) {
      Log.e('AirPlayService', '应用设置失败', e);
    }
  }

  void _applyPerformanceSettings(AirPlaySettings settings) {
    // 应用性能模式
    switch (settings.performanceMode) {
      case PerformanceMode.powersave:
        _performanceMonitor.setPerformanceProfile(PerformanceProfile.powersave);
        break;
      case PerformanceMode.balanced:
        _performanceMonitor.setPerformanceProfile(PerformanceProfile.balanced);
        break;
      case PerformanceMode.performance:
        _performanceMonitor
            .setPerformanceProfile(PerformanceProfile.performance);
        break;
      case PerformanceMode.gaming:
        _performanceMonitor.setPerformanceProfile(PerformanceProfile.gaming);
        break;
    }

    Log.d('AirPlayService', '性能模式已应用: ${settings.performanceMode}');
  }

  void _applyVideoSettings(AirPlaySettings settings) {
    // 应用视频解码器设置
    _decoderService.updateSettings({
      'hardwareAcceleration': settings.hardwareAcceleration,
      'videoBitrate': settings.videoBitrate,
      'videoFramerate': settings.videoFramerate,
      'videoCodec': settings.videoCodec,
    });

    Log.d('AirPlayService',
        '视频设置已应用: ${settings.videoQuality}, ${settings.videoBitrate}kbps, ${settings.videoFramerate}fps');
  }

  void _applyAudioSettings(AirPlaySettings settings) {
    // 应用音频解码器设置
    _audioDecoderService.updateSettings({
      'audioBitrate': settings.audioBitrate,
      'audioSampleRate': settings.audioSampleRate,
      'audioCodec': settings.audioCodec,
      'audioEnhancement': settings.audioEnhancement,
    });

    Log.d('AirPlayService',
        '音频设置已应用: ${settings.audioQuality}, ${settings.audioBitrate}kbps, ${settings.audioSampleRate}Hz');
  }

  void _applySyncSettings(AirPlaySettings settings) {
    // 更新同步服务设置
    if (settings.adaptiveSync) {
      // 启用自适应同步
      Log.d('AirPlayService', '启用自适应同步');
    }

    // 通过反射或配置接口更新同步阈值
    // 注意：这里需要在AudioVideoSyncService中添加设置更新方法
    Log.d('AirPlayService',
        '同步设置已应用: 阈值${settings.syncThreshold}ms, 抖动缓冲${settings.jitterBufferSize}ms');
  }

  void _applyNetworkSettings(AirPlaySettings settings) {
    // 应用网络设置
    _networkMonitor.updateSettings({
      'networkMode': settings.networkMode,
      'lowLatencyMode': settings.lowLatencyMode,
      'connectionTimeout': settings.connectionTimeout,
      'autoReconnect': settings.autoReconnect,
    });

    Log.d('AirPlayService',
        '网络设置已应用: ${settings.networkMode}, 低延迟=${settings.lowLatencyMode}');
  }

  void _applyDebugSettings(AirPlaySettings settings) {
    // 应用调试设置
    if (settings.debugMode != Log.isDebugMode) {
      Log.setDebugMode(settings.debugMode);
      Log.d('AirPlayService', '调试模式已${settings.debugMode ? '启用' : '禁用'}');
    }

    if (settings.verboseLogging != Log.isVerboseMode) {
      Log.setVerboseMode(settings.verboseLogging);
      Log.d('AirPlayService', '详细日志已${settings.verboseLogging ? '启用' : '禁用'}');
    }
  }
}
