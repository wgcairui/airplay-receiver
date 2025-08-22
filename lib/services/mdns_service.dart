import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../constants/app_constants.dart';
import 'logger_service.dart';

class MdnsService {
  static const MethodChannel _methodChannel = MethodChannel('com.airplay.padcast.receiver/mdns');
  String? _localIP;
  bool _isRunning = false;
  bool _isStarting = false;
  Timer? _healthCheckTimer;
  Timer? _retryTimer;
  int _startAttempts = 0;
  static const int _maxRetries = 3;
  static const Duration _healthCheckInterval = Duration(seconds: 30);
  static const Duration _retryDelay = Duration(seconds: 5);

  bool get isRunning => _isRunning;
  bool get isStarting => _isStarting;
  String? get localIP => _localIP;

  Future<void> startAdvertising() async {
    if (_isRunning || _isStarting) {
      Log.w('MdnsService', '服务正在运行或启动中，跳过启动请求');
      return;
    }

    _isStarting = true;
    _startAttempts++;

    try {
      Log.i('MdnsService', '开始启动mDNS广播服务 (尝试 $_startAttempts/$_maxRetries)');
      
      // 获取本地IP地址，支持重试
      _localIP = await _getLocalIPWithRetry();
      if (_localIP == null) {
        throw Exception('无法获取本地IP地址');
      }

      final deviceName = AppConstants.deviceName.replaceAll(' ', '-');
      final serviceName = '$deviceName.${AppConstants.mdnsServiceType}.local';
      final txtRecords = _buildTxtRecords();

      Log.d('MdnsService', '使用IP地址: $_localIP, 服务名: $serviceName');

      // 使用原生mDNS插件启动广播
      await _methodChannel.invokeMethod('startAdvertising', {
        'serviceName': serviceName,
        'port': AppConstants.airplayPort,
        'txtRecords': txtRecords,
        'localIP': _localIP,
      });

      _isRunning = true;
      _startAttempts = 0; // 重置重试计数
      
      // 启动健康检查
      _startHealthCheck();
      
      Log.i('MdnsService', 'mDNS广播服务已启动: $_localIP:${AppConstants.airplayPort}');
      Log.i('MdnsService', '服务名称: $serviceName');
      
    } catch (e, stackTrace) {
      Log.e('MdnsService', '启动mDNS服务失败', e, stackTrace);
      
      // 如果还有重试次数，稍后重试
      if (_startAttempts < _maxRetries) {
        Log.w('MdnsService', '将在${_retryDelay.inSeconds}秒后重试 ($_startAttempts/$_maxRetries)');
        _scheduleRetry();
      } else {
        Log.e('MdnsService', '已达到最大重试次数，停止尝试');
        _startAttempts = 0;
        await _cleanup();
      }
      rethrow;
    } finally {
      _isStarting = false;
    }
  }
  
  Future<String?> _getLocalIPWithRetry() async {
    for (int i = 0; i < 3; i++) {
      final ip = await _getLocalIP();
      if (ip != null) {
        return ip;
      }
      if (i < 2) {
        Log.w('MdnsService', '获取IP失败，重试中...');
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    return null;
  }
  
  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(_retryDelay, () {
      if (!_isRunning) {
        Log.i('MdnsService', '重试启动mDNS服务');
        startAdvertising().catchError((e) {
          Log.e('MdnsService', '重试启动失败', e);
        });
      }
    });
  }
  
  void _startHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (timer) async {
      if (_isRunning) {
        final currentIP = await _getLocalIP();
        if (currentIP != _localIP) {
          Log.w('MdnsService', 'IP地址已变化: $_localIP -> $currentIP, 重启服务');
          await _restartService();
        } else {
          Log.d('MdnsService', 'mDNS服务健康检查通过');
        }
      } else {
        timer.cancel();
      }
    });
  }
  
  Future<void> _restartService() async {
    Log.i('MdnsService', '重启mDNS服务');
    try {
      await stopAdvertising();
      await Future.delayed(const Duration(milliseconds: 500));
      await startAdvertising();
    } catch (e) {
      Log.e('MdnsService', '重启mDNS服务失败', e);
    }
  }

  Future<void> stopAdvertising() async {
    if (!_isRunning && !_isStarting) {
      Log.d('MdnsService', '服务未运行，跳过停止请求');
      return;
    }

    try {
      Log.i('MdnsService', '停止mDNS广播服务');
      
      // 取消所有定时器
      _healthCheckTimer?.cancel();
      _retryTimer?.cancel();
      
      // 如果服务正在运行，停止原生服务
      if (_isRunning) {
        await _methodChannel.invokeMethod('stopAdvertising');
      }
      
      await _cleanup();
      Log.i('MdnsService', 'mDNS广播服务已停止');
      
    } catch (e, stackTrace) {
      Log.e('MdnsService', '停止mDNS服务失败', e, stackTrace);
      // 即使停止失败，也要清理状态
      await _cleanup();
    }
  }
  
  Future<void> _cleanup() async {
    _isRunning = false;
    _isStarting = false;
    _startAttempts = 0;
    _healthCheckTimer?.cancel();
    _retryTimer?.cancel();
    _healthCheckTimer = null;
    _retryTimer = null;
    Log.d('MdnsService', 'mDNS服务资源已清理');
  }


  Map<String, String> _buildTxtRecords() {
    final deviceId = _generateDeviceId();
    final piId = _generatePiId();
    
    Log.d('MdnsService', '构建TXT记录 - DeviceID: $deviceId, PI: $piId');
    
    return {
      // AirPlay版本和功能
      'txtvers': '1',
      'srcvers': '366.0',  // 更新到较新版本
      'features': '0x5A7FFFF7,0x1E',  // 支持视频+音频流

      // 设备信息
      'model': 'OPPO,Pad4Pro',
      'deviceid': deviceId,
      'pi': piId,

      // 显示能力
      'vv': '2',
      'flags': '0x244',  // 更新flags
      'statusflags': '0x44',
      'protovers': '1.0',

      // PIN码设置 (已禁用)
      'pw': '0',  // 0表示不需要PIN码
      
      // 音频编码支持
      'am': 'OPPO,Pad4Pro',
      'tp': 'UDP',
      'vs': '366.0',
      'sm': '0',

      // 其他AirPlay参数
      'da': 'true',   // 支持AirPlay Display
      'sv': 'false',  // 不需要屏幕验证
      'et': '0,3,5',  // 支持的编码类型
      'cn': '0,1,2,3', // 支持的压缩方式
      'ch': '2',      // 立体声
      'ss': '16',     // 采样深度
      'sr': '44100,48000', // 采样率
      
      // 额外的兼容性参数
      'pk': '0123456789abcdef0123456789abcdef01234567',
      'vn': '65537',
      'ov': '16.0.0',  // 模拟的系统版本
    };
  }
  
  String _generateDeviceId() {
    // 基于设备名和IP生成一致的设备ID
    final base = '${AppConstants.deviceName}${_localIP ?? 'unknown'}';
    final hash = base.hashCode.abs().toRadixString(16).padLeft(12, '0');
    return '${hash.substring(0, 2)}:${hash.substring(2, 4)}:${hash.substring(4, 6)}:${hash.substring(6, 8)}:${hash.substring(8, 10)}:${hash.substring(10, 12)}';
  }
  
  String _generatePiId() {
    // 生成UUID格式的PI ID
    final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(16);
    final random = (_localIP?.hashCode ?? 0).abs().toRadixString(16).padLeft(8, '0');
    return '${timestamp.substring(0, 8)}-${random.substring(0, 4)}-4000-8000-${timestamp.substring(8)}${random.substring(4)}';
  }

  Future<String?> _getLocalIP() async {
    try {
      Log.d('MdnsService', '开始获取本地IP地址');
      
      // 首先尝试从WiFi获取IP
      final wifiIP = await NetworkInfo().getWifiIP();
      if (_isValidIP(wifiIP)) {
        Log.d('MdnsService', '从WiFi获取到IP: $wifiIP');
        return wifiIP;
      }

      // 如果WiFi获取失败，尝试从网络接口获取
      Log.d('MdnsService', 'WiFi IP无效，尝试从网络接口获取');
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      
      for (final interface in interfaces) {
        Log.d('MdnsService', '检查网络接口: ${interface.name}');
        
        // 优先选择WiFi相关接口
        final isWifiInterface = interface.name.toLowerCase().contains('wlan') ||
                               interface.name.toLowerCase().contains('wifi') ||
                               interface.name.toLowerCase().contains('en0');
        
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && 
              !addr.isLoopback && 
              _isValidIP(addr.address)) {
            Log.d('MdnsService', '找到有效IP: ${addr.address} (接口: ${interface.name})');
            
            if (isWifiInterface) {
              Log.i('MdnsService', '优先使用WiFi接口IP: ${addr.address}');
              return addr.address;
            }
            
            // 如果不是WiFi接口但是有效IP，先记录下来
            _localIP ??= addr.address;
          }
        }
      }

      // 如果找到任何有效IP，使用它
      if (_localIP != null) {
        Log.i('MdnsService', '使用网络接口IP: $_localIP');
        return _localIP;
      }

      Log.w('MdnsService', '未找到有效的本地IP地址');
      return null;
      
    } catch (e, stackTrace) {
      Log.e('MdnsService', '获取本地IP失败', e, stackTrace);
      return null;
    }
  }
  
  bool _isValidIP(String? ip) {
    if (ip == null || ip.isEmpty) return false;
    
    // 检查无效IP
    if (ip == '0.0.0.0' || ip == '127.0.0.1') return false;
    
    // 检查IP格式
    final ipPattern = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$');
    final match = ipPattern.firstMatch(ip);
    if (match == null) return false;
    
    // 检查每个字段是否在有效范围内
    for (int i = 1; i <= 4; i++) {
      final octet = int.tryParse(match.group(i)!);
      if (octet == null || octet < 0 || octet > 255) return false;
    }
    
    return true;
  }

  Future<void> dispose() async {
    Log.i('MdnsService', '开始清理mDNS服务资源');
    try {
      await stopAdvertising();
      Log.i('MdnsService', 'mDNS服务资源清理完成');
    } catch (e) {
      Log.e('MdnsService', '清理mDNS服务资源时出错', e);
    }
  }
}
