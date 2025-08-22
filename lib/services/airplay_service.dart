import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import '../constants/app_constants.dart';
import '../models/connection_state.dart' show ConnectionStatus, AirPlayConnectionState;
import 'mdns_service.dart';
import 'network_monitor_service.dart';
import 'rtsp_service.dart';
import 'performance_monitor_service.dart';
import 'audio_video_sync_service.dart';
import 'video_decoder_service.dart';
import 'audio_decoder_service.dart';
import 'performance_optimization_service.dart';
import 'logger_service.dart';

class AirPlayService {
  HttpServer? _httpServer;
  final MdnsService _mdnsService = MdnsService();
  final NetworkMonitorService _networkMonitor = NetworkMonitorService();
  final RtspService _rtspService = RtspService();
  final PerformanceMonitorService _performanceMonitor = PerformanceMonitorService();
  final AudioVideoSyncService _syncService = AudioVideoSyncService();
  final VideoDecoderService _decoderService = VideoDecoderService();
  final AudioDecoderService _audioDecoderService = AudioDecoderService();
  PerformanceOptimizationService? _optimizationService;
  
  final StreamController<AirPlayConnectionState> _stateController = 
      StreamController<AirPlayConnectionState>.broadcast();
  
  Stream<AirPlayConnectionState> get stateStream => _stateController.stream;
  AirPlayConnectionState _currentState = const AirPlayConnectionState();
  
  AirPlayConnectionState get currentState => _currentState;
  NetworkMonitorService get networkMonitor => _networkMonitor;
  RtspService get rtspService => _rtspService;
  PerformanceMonitorService get performanceMonitor => _performanceMonitor;
  AudioVideoSyncService get syncService => _syncService;
  VideoDecoderService get decoderService => _decoderService;
  AudioDecoderService get audioDecoderService => _audioDecoderService;
  PerformanceOptimizationService? get optimizationService => _optimizationService;
  
  void _updateState(AirPlayConnectionState newState) {
    _currentState = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }
  
  Future<void> startService() async {
    try {
      Log.i('AirPlayService', '开始启动AirPlay服务');
      _updateState(_currentState.copyWith(status: ConnectionStatus.discovering));
      
      // 初始化优化服务
      Log.d('AirPlayService', '初始化性能优化服务');
      _optimizationService = PerformanceOptimizationService(_performanceMonitor);
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
      Log.i('AirPlayService', '网络连接正常: ${_networkMonitor.currentNetworkInfo.ipAddress}');
      
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
      _rtspService.messageStream.listen(_handleRtspMessage);
      
      // 启动音视频同步服务
      Log.d('AirPlayService', '启动音视频同步服务');
      _syncService.startSync();
      
      // 启动性能优化服务
      _optimizationService?.startOptimization();
      
      _updateState(_currentState.copyWith(status: ConnectionStatus.disconnected));
      Log.i('AirPlayService', 'AirPlay服务启动完成，等待设备连接');
    } catch (e, stackTrace) {
      Log.e('AirPlayService', '启动服务失败', e, stackTrace);
      _updateState(_currentState.copyWith(
        status: ConnectionStatus.error,
        errorMessage: '启动服务失败: $e'
      ));
      rethrow;
    }
  }
  
  Future<void> _startHttpServer() async {
    final router = Router();
    
    // AirPlay设备信息接口
    router.get('/info', (shelf.Request request) {
      final deviceInfo = {
        'name': AppConstants.deviceName,
        'model': 'OPPO Pad 4 Pro',
        'srcvers': '220.68',
        'pi': '00000000-0000-0000-0000-000000000000',
        'vv': 2,
        'features': '0x5A7FFFF7,0x1E',
        'flags': '0x44',
        'statusflags': '0x44',
        'deviceid': '00:00:00:00:00:00',
        'displays': AppConstants.airplayFeatures['displays'],
      };
      
      return shelf.Response.ok(
        jsonEncode(deviceInfo),
        headers: {'Content-Type': 'application/json'},
      );
    });
    
    // 处理连接请求
    router.post('/pair-setup', (shelf.Request request) async {
      _updateState(_currentState.copyWith(status: ConnectionStatus.connecting));
      
      // 简化的配对响应（无PIN码）
      final response = {
        'status': 0,
        'sessionID': '12345678-1234-1234-1234-123456789ABC'
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
      
      _updateState(_currentState.copyWith(
        status: ConnectionStatus.streaming,
        connectedDeviceIP: clientIP,
        connectedDeviceName: 'Mac设备'
      ));
      
      return shelf.Response.ok('Stream started');
    });
    
    final handler = const shelf.Pipeline()
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
    await _mdnsService.stopAdvertising();
    await _networkMonitor.stopMonitoring();
    await _rtspService.stopRtspServer();
    await _performanceMonitor.stopMonitoring();
    _syncService.stopSync();
    _optimizationService?.stopOptimization();
    await _decoderService.dispose();
    await _httpServer?.close();
    
    _updateState(const AirPlayConnectionState(status: ConnectionStatus.disconnected));
    print('AirPlay服务已停止');
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
        _optimizationService?.setOptimizationLevel(OptimizationLevel.performance);
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

  void dispose() {
    _stateController.close();
    _mdnsService.dispose();
    _networkMonitor.dispose();
    _rtspService.dispose();
    _performanceMonitor.dispose();
    _syncService.dispose();
    _optimizationService?.dispose();
    _decoderService.dispose();
    _audioDecoderService.dispose();
  }
}