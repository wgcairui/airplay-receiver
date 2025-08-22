class AppConstants {
  // 应用信息
  static const String appName = 'PadCast';
  static const String deviceName = 'OPPO Pad - PadCast';
  static const String appVersion = '1.0.0';

  // 网络配置
  static const int airplayPort = 7000;
  static const int rtspPort = 7001;
  static const String mdnsServiceType = '_airplay._tcp';

  // AirPlay配置
  static const Map<String, dynamic> airplayFeatures = {
    'audioFormats': [
      {
        'type': 100,
        'audioInputFormats': 0x01000000,
        'audioOutputFormats': 0x01000000
      }
    ],
    'videoFormats': [
      {'type': 0, 'codec': 0, 'modes': 1}
    ],
    'displays': [
      {
        'uuid': '00000000-0000-0000-0000-000000000000',
        'width': 3392,
        'height': 2400,
        'widthPhysical': 0,
        'heightPhysical': 0,
        'widthPixels': 3392,
        'heightPixels': 2400,
        'refreshRate': 144.0,
        'maxFPS': 144,
        'overscanned': false,
        'rotating': false,
        'uiOverride': false
      }
    ]
  };

  // UI配置
  static const double defaultPadding = 16.0;
  static const double cardRadius = 12.0;
  static const double buttonRadius = 8.0;

  // 延迟和性能目标
  static const int targetLatencyMs = 50;
  static const int maxCpuUsagePercent = 30;
  static const int maxMemoryUsageMB = 500;
}
