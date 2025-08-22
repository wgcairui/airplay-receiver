import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';

class AppNetworkInfo {
  final String? ssid;
  final String? bssid;
  final String? ipAddress;
  final String? subnetMask;
  final String? gateway;
  final bool isConnected;
  final NetworkType type;

  const AppNetworkInfo({
    this.ssid,
    this.bssid,
    this.ipAddress,
    this.subnetMask,
    this.gateway,
    required this.isConnected,
    required this.type,
  });
}

enum NetworkType { wifi, ethernet, mobile, none }

class NetworkMonitorService {
  final Connectivity _connectivity = Connectivity();
  // Remove unused field
  Timer? _monitorTimer;

  final StreamController<AppNetworkInfo> _networkStateController =
      StreamController<AppNetworkInfo>.broadcast();

  Stream<AppNetworkInfo> get networkStream => _networkStateController.stream;

  AppNetworkInfo _currentNetworkInfo =
      const AppNetworkInfo(isConnected: false, type: NetworkType.none);

  AppNetworkInfo get currentNetworkInfo => _currentNetworkInfo;

  Future<void> startMonitoring() async {
    // 立即检查一次网络状态
    await _checkNetworkStatus();

    // 监听连接状态变化
    _connectivity.onConnectivityChanged.listen((_) {
      _checkNetworkStatus();
    });

    // 定期检查网络状态 (每5秒)
    _monitorTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkNetworkStatus();
    });

    print('网络监控服务已启动');
  }

  Future<void> stopMonitoring() async {
    _monitorTimer?.cancel();
    _monitorTimer = null;
    print('网络监控服务已停止');
  }

  Future<void> _checkNetworkStatus() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();

      NetworkType networkType = NetworkType.none;
      bool isConnected = false;
      String? ssid;
      String? bssid;
      String? ipAddress;
      String? gateway;
      String? subnetMask;

      if (connectivityResult.contains(ConnectivityResult.wifi)) {
        networkType = NetworkType.wifi;
        isConnected = true;

        try {
          final networkInfoService = NetworkInfo();
          ssid = await networkInfoService.getWifiName();
          bssid = await networkInfoService.getWifiBSSID();
          ipAddress = await networkInfoService.getWifiIP();
          gateway = await networkInfoService.getWifiGatewayIP();
          subnetMask = await networkInfoService.getWifiSubmask();
        } catch (e) {
          print('获取WiFi信息失败: $e');
        }
      } else if (connectivityResult.contains(ConnectivityResult.ethernet)) {
        networkType = NetworkType.ethernet;
        isConnected = true;

        // 获取以太网IP地址
        try {
          final interfaces = await NetworkInterface.list();
          for (final interface in interfaces) {
            if (interface.name.contains('eth') ||
                interface.name.contains('en') ||
                interface.name.contains('Ethernet')) {
              for (final addr in interface.addresses) {
                if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
                  ipAddress = addr.address;
                  break;
                }
              }
            }
          }
        } catch (e) {
          print('获取以太网信息失败: $e');
        }
      } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
        networkType = NetworkType.mobile;
        isConnected = true;

        // 移动网络通常无法获取详细网络信息
        ipAddress = '移动网络';
      }

      final newNetworkInfo = AppNetworkInfo(
        ssid: ssid,
        bssid: bssid,
        ipAddress: ipAddress,
        gateway: gateway,
        subnetMask: subnetMask,
        isConnected: isConnected,
        type: networkType,
      );

      if (_hasNetworkInfoChanged(newNetworkInfo)) {
        _currentNetworkInfo = newNetworkInfo;
        _networkStateController.add(newNetworkInfo);
      }
    } catch (e) {
      print('检查网络状态失败: $e');

      // 网络检查失败时设置为未连接状态
      final errorNetworkInfo = const AppNetworkInfo(
        isConnected: false,
        type: NetworkType.none,
      );

      if (_hasNetworkInfoChanged(errorNetworkInfo)) {
        _currentNetworkInfo = errorNetworkInfo;
        _networkStateController.add(errorNetworkInfo);
      }
    }
  }

  bool _hasNetworkInfoChanged(AppNetworkInfo newInfo) {
    return _currentNetworkInfo.isConnected != newInfo.isConnected ||
        _currentNetworkInfo.type != newInfo.type ||
        _currentNetworkInfo.ssid != newInfo.ssid ||
        _currentNetworkInfo.ipAddress != newInfo.ipAddress;
  }

  void dispose() {
    stopMonitoring();
    _networkStateController.close();
  }

  /// 更新设置
  void updateSettings(Map<String, dynamic> settings) {
    // 这里可以添加网络监控相关的设置更新逻辑
    if (settings.containsKey('lowLatencyMode')) {
      // 可以调整监控频率等
    }
    if (settings.containsKey('connectionTimeout')) {
      // 可以调整连接超时设置
    }

    print('网络监控设置已更新: $settings');
  }
}
