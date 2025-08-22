import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../constants/app_constants.dart';

class MdnsService {
  static const MethodChannel _methodChannel = MethodChannel('com.airplay.padcast.receiver/mdns');
  String? _localIP;
  bool _isRunning = false;

  bool get isRunning => _isRunning;
  String? get localIP => _localIP;

  Future<void> startAdvertising() async {
    if (_isRunning) return;

    try {
      _localIP = await _getLocalIP();
      if (_localIP == null) {
        throw Exception('无法获取本地IP地址');
      }

      final deviceName = AppConstants.deviceName.replaceAll(' ', '-');
      final serviceName = '$deviceName.${AppConstants.mdnsServiceType}.local';
      final txtRecords = _buildTxtRecords();

      // 使用原生mDNS插件启动广播
      await _methodChannel.invokeMethod('startAdvertising', {
        'serviceName': serviceName,
        'port': AppConstants.airplayPort,
        'txtRecords': txtRecords,
        'localIP': _localIP,
      });

      _isRunning = true;
      print('mDNS广播服务已启动: $_localIP:${AppConstants.airplayPort}');
      print('服务名称: $serviceName');
    } catch (e) {
      print('启动mDNS服务失败: $e');
      await stopAdvertising();
      rethrow;
    }
  }

  Future<void> stopAdvertising() async {
    if (!_isRunning) return;

    try {
      await _methodChannel.invokeMethod('stopAdvertising');
      _isRunning = false;
      print('mDNS广播服务已停止');
    } catch (e) {
      print('停止mDNS服务失败: $e');
      _isRunning = false;
    }
  }


  Map<String, String> _buildTxtRecords() {
    return {
      // AirPlay版本和功能
      'txtvers': '1',
      'srcvers': '220.68',
      'features': '0x5A7FFFF7,0x1E',

      // 设备信息
      'model': 'OPPO Pad',
      'deviceid': '00:00:00:00:00:00',
      'pi': '00000000-0000-0000-0000-000000000000',

      // 显示能力
      'vv': '2',
      'flags': '0x44',
      'statusflags': '0x44',
      'protovers': '1.0',

      // PIN码设置 (已禁用)
      'pw': '0', // 0表示不需要PIN码
      // 音频编码支持
      'am': 'OPPO Pad',
      'tp': 'UDP',
      'vs': '220.68',
      'sm': '0',

      // 其他AirPlay参数
      'da': 'true',
      'sv': 'false',
      'et': '0,3,5',
      'cn': '0,1,2,3',
      'ch': '2',
      'ss': '16',
      'sr': '44100,48000',
    };
  }

  Future<String?> _getLocalIP() async {
    try {
      // 首先尝试从WiFi获取IP
      final wifiIP = await NetworkInfo().getWifiIP();
      if (wifiIP != null && wifiIP.isNotEmpty && wifiIP != '0.0.0.0') {
        return wifiIP;
      }

      // 如果WiFi获取失败，尝试从网络接口获取
      final interfaces = await NetworkInterface.list();
      for (final interface in interfaces) {
        // 跳过loopback接口
        if (interface.name.contains('lo')) continue;

        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }

      return null;
    } catch (e) {
      print('获取本地IP失败: $e');
      return null;
    }
  }

  void dispose() {
    stopAdvertising();
  }
}
