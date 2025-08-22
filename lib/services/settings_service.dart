import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'logger_service.dart';

enum VideoQuality {
  low, // 720p, 30fps, 2Mbps
  medium, // 1080p, 30fps, 5Mbps
  high, // 1080p, 60fps, 8Mbps
  ultra, // 4K, 30fps, 15Mbps
  auto, // 自动调整
}

enum AudioQuality {
  low, // 16kHz, 128kbps
  medium, // 44.1kHz, 256kbps
  high, // 48kHz, 320kbps
  lossless, // 48kHz, 无损
}

enum PerformanceMode {
  powersave, // 省电模式
  balanced, // 平衡模式
  performance, // 性能模式
  gaming, // 游戏模式
}

enum NetworkMode {
  auto, // 自动检测
  wifiOnly, // 仅WiFi
  ethernet, // 以太网优先
  mobileData, // 移动数据
}

class AirPlaySettings {
  // 视频设置
  VideoQuality videoQuality;
  bool hardwareAcceleration;
  int videoBitrate; // kbps
  int videoFramerate; // fps
  String videoCodec; // h264, h265

  // 音频设置
  AudioQuality audioQuality;
  int audioBitrate; // kbps
  int audioSampleRate; // Hz
  String audioCodec; // aac, alac
  bool audioEnhancement;

  // 同步设置
  double syncThreshold; // ms
  bool adaptiveSync;
  double jitterBufferSize; // ms
  bool lipSyncCorrection;

  // 网络设置
  NetworkMode networkMode;
  int bufferSize; // frames
  bool lowLatencyMode;
  int connectionTimeout; // seconds
  bool autoReconnect;

  // 性能设置
  PerformanceMode performanceMode;
  bool thermalThrottling;
  bool backgroundProcessing;
  int maxConcurrentConnections;

  // 显示设置
  bool fullScreenMode;
  double aspectRatio; // 0.0 for auto
  bool displayRotation;
  double brightness; // 0.0-1.0

  // 高级设置
  bool debugMode;
  bool verboseLogging;
  bool telemetryEnabled;
  String deviceName;
  bool discoverable;
  int httpPort;
  int rtspPort;

  AirPlaySettings({
    this.videoQuality = VideoQuality.auto,
    this.hardwareAcceleration = true,
    this.videoBitrate = 5000,
    this.videoFramerate = 30,
    this.videoCodec = 'h264',
    this.audioQuality = AudioQuality.high,
    this.audioBitrate = 320,
    this.audioSampleRate = 48000,
    this.audioCodec = 'aac',
    this.audioEnhancement = true,
    this.syncThreshold = 40.0,
    this.adaptiveSync = true,
    this.jitterBufferSize = 50.0,
    this.lipSyncCorrection = true,
    this.networkMode = NetworkMode.auto,
    this.bufferSize = 10,
    this.lowLatencyMode = false,
    this.connectionTimeout = 30,
    this.autoReconnect = true,
    this.performanceMode = PerformanceMode.balanced,
    this.thermalThrottling = true,
    this.backgroundProcessing = false,
    this.maxConcurrentConnections = 3,
    this.fullScreenMode = true,
    this.aspectRatio = 0.0,
    this.displayRotation = true,
    this.brightness = 1.0,
    this.debugMode = false,
    this.verboseLogging = false,
    this.telemetryEnabled = true,
    this.deviceName = 'OPPO Pad - PadCast',
    this.discoverable = true,
    this.httpPort = 7000,
    this.rtspPort = 7001,
  });

  Map<String, dynamic> toJson() {
    return {
      'videoQuality': videoQuality.toString(),
      'hardwareAcceleration': hardwareAcceleration,
      'videoBitrate': videoBitrate,
      'videoFramerate': videoFramerate,
      'videoCodec': videoCodec,
      'audioQuality': audioQuality.toString(),
      'audioBitrate': audioBitrate,
      'audioSampleRate': audioSampleRate,
      'audioCodec': audioCodec,
      'audioEnhancement': audioEnhancement,
      'syncThreshold': syncThreshold,
      'adaptiveSync': adaptiveSync,
      'jitterBufferSize': jitterBufferSize,
      'lipSyncCorrection': lipSyncCorrection,
      'networkMode': networkMode.toString(),
      'bufferSize': bufferSize,
      'lowLatencyMode': lowLatencyMode,
      'connectionTimeout': connectionTimeout,
      'autoReconnect': autoReconnect,
      'performanceMode': performanceMode.toString(),
      'thermalThrottling': thermalThrottling,
      'backgroundProcessing': backgroundProcessing,
      'maxConcurrentConnections': maxConcurrentConnections,
      'fullScreenMode': fullScreenMode,
      'aspectRatio': aspectRatio,
      'displayRotation': displayRotation,
      'brightness': brightness,
      'debugMode': debugMode,
      'verboseLogging': verboseLogging,
      'telemetryEnabled': telemetryEnabled,
      'deviceName': deviceName,
      'discoverable': discoverable,
      'httpPort': httpPort,
      'rtspPort': rtspPort,
    };
  }

  factory AirPlaySettings.fromJson(Map<String, dynamic> json) {
    return AirPlaySettings(
      videoQuality: VideoQuality.values.firstWhere(
        (e) => e.toString() == json['videoQuality'],
        orElse: () => VideoQuality.auto,
      ),
      hardwareAcceleration: json['hardwareAcceleration'] ?? true,
      videoBitrate: json['videoBitrate'] ?? 5000,
      videoFramerate: json['videoFramerate'] ?? 30,
      videoCodec: json['videoCodec'] ?? 'h264',
      audioQuality: AudioQuality.values.firstWhere(
        (e) => e.toString() == json['audioQuality'],
        orElse: () => AudioQuality.high,
      ),
      audioBitrate: json['audioBitrate'] ?? 320,
      audioSampleRate: json['audioSampleRate'] ?? 48000,
      audioCodec: json['audioCodec'] ?? 'aac',
      audioEnhancement: json['audioEnhancement'] ?? true,
      syncThreshold: json['syncThreshold']?.toDouble() ?? 40.0,
      adaptiveSync: json['adaptiveSync'] ?? true,
      jitterBufferSize: json['jitterBufferSize']?.toDouble() ?? 50.0,
      lipSyncCorrection: json['lipSyncCorrection'] ?? true,
      networkMode: NetworkMode.values.firstWhere(
        (e) => e.toString() == json['networkMode'],
        orElse: () => NetworkMode.auto,
      ),
      bufferSize: json['bufferSize'] ?? 10,
      lowLatencyMode: json['lowLatencyMode'] ?? false,
      connectionTimeout: json['connectionTimeout'] ?? 30,
      autoReconnect: json['autoReconnect'] ?? true,
      performanceMode: PerformanceMode.values.firstWhere(
        (e) => e.toString() == json['performanceMode'],
        orElse: () => PerformanceMode.balanced,
      ),
      thermalThrottling: json['thermalThrottling'] ?? true,
      backgroundProcessing: json['backgroundProcessing'] ?? false,
      maxConcurrentConnections: json['maxConcurrentConnections'] ?? 3,
      fullScreenMode: json['fullScreenMode'] ?? true,
      aspectRatio: json['aspectRatio']?.toDouble() ?? 0.0,
      displayRotation: json['displayRotation'] ?? true,
      brightness: json['brightness']?.toDouble() ?? 1.0,
      debugMode: json['debugMode'] ?? false,
      verboseLogging: json['verboseLogging'] ?? false,
      telemetryEnabled: json['telemetryEnabled'] ?? true,
      deviceName: json['deviceName'] ?? 'OPPO Pad - PadCast',
      discoverable: json['discoverable'] ?? true,
      httpPort: json['httpPort'] ?? 7000,
      rtspPort: json['rtspPort'] ?? 7001,
    );
  }

  AirPlaySettings copyWith({
    VideoQuality? videoQuality,
    bool? hardwareAcceleration,
    int? videoBitrate,
    int? videoFramerate,
    String? videoCodec,
    AudioQuality? audioQuality,
    int? audioBitrate,
    int? audioSampleRate,
    String? audioCodec,
    bool? audioEnhancement,
    double? syncThreshold,
    bool? adaptiveSync,
    double? jitterBufferSize,
    bool? lipSyncCorrection,
    NetworkMode? networkMode,
    int? bufferSize,
    bool? lowLatencyMode,
    int? connectionTimeout,
    bool? autoReconnect,
    PerformanceMode? performanceMode,
    bool? thermalThrottling,
    bool? backgroundProcessing,
    int? maxConcurrentConnections,
    bool? fullScreenMode,
    double? aspectRatio,
    bool? displayRotation,
    double? brightness,
    bool? debugMode,
    bool? verboseLogging,
    bool? telemetryEnabled,
    String? deviceName,
    bool? discoverable,
    int? httpPort,
    int? rtspPort,
  }) {
    return AirPlaySettings(
      videoQuality: videoQuality ?? this.videoQuality,
      hardwareAcceleration: hardwareAcceleration ?? this.hardwareAcceleration,
      videoBitrate: videoBitrate ?? this.videoBitrate,
      videoFramerate: videoFramerate ?? this.videoFramerate,
      videoCodec: videoCodec ?? this.videoCodec,
      audioQuality: audioQuality ?? this.audioQuality,
      audioBitrate: audioBitrate ?? this.audioBitrate,
      audioSampleRate: audioSampleRate ?? this.audioSampleRate,
      audioCodec: audioCodec ?? this.audioCodec,
      audioEnhancement: audioEnhancement ?? this.audioEnhancement,
      syncThreshold: syncThreshold ?? this.syncThreshold,
      adaptiveSync: adaptiveSync ?? this.adaptiveSync,
      jitterBufferSize: jitterBufferSize ?? this.jitterBufferSize,
      lipSyncCorrection: lipSyncCorrection ?? this.lipSyncCorrection,
      networkMode: networkMode ?? this.networkMode,
      bufferSize: bufferSize ?? this.bufferSize,
      lowLatencyMode: lowLatencyMode ?? this.lowLatencyMode,
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      performanceMode: performanceMode ?? this.performanceMode,
      thermalThrottling: thermalThrottling ?? this.thermalThrottling,
      backgroundProcessing: backgroundProcessing ?? this.backgroundProcessing,
      maxConcurrentConnections:
          maxConcurrentConnections ?? this.maxConcurrentConnections,
      fullScreenMode: fullScreenMode ?? this.fullScreenMode,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      displayRotation: displayRotation ?? this.displayRotation,
      brightness: brightness ?? this.brightness,
      debugMode: debugMode ?? this.debugMode,
      verboseLogging: verboseLogging ?? this.verboseLogging,
      telemetryEnabled: telemetryEnabled ?? this.telemetryEnabled,
      deviceName: deviceName ?? this.deviceName,
      discoverable: discoverable ?? this.discoverable,
      httpPort: httpPort ?? this.httpPort,
      rtspPort: rtspPort ?? this.rtspPort,
    );
  }
}

class SettingsService {
  static const String _settingsKey = 'airplay_settings';

  AirPlaySettings _currentSettings = AirPlaySettings();
  SharedPreferences? _prefs;

  final StreamController<AirPlaySettings> _settingsController =
      StreamController<AirPlaySettings>.broadcast();

  Stream<AirPlaySettings> get settingsStream => _settingsController.stream;
  AirPlaySettings get currentSettings => _currentSettings;

  Future<void> initialize() async {
    try {
      Log.i('SettingsService', '初始化设置服务');

      _prefs = await SharedPreferences.getInstance();
      await _loadSettings();

      Log.i('SettingsService', '设置服务初始化完成');
    } catch (e) {
      Log.e('SettingsService', '初始化设置服务失败', e);
      // 使用默认设置
      _currentSettings = AirPlaySettings();
    }
  }

  Future<void> _loadSettings() async {
    try {
      final settingsJson = _prefs?.getString(_settingsKey);

      if (settingsJson != null) {
        final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
        _currentSettings = AirPlaySettings.fromJson(settingsMap);

        Log.d('SettingsService', '已加载用户设置');
      } else {
        Log.d('SettingsService', '使用默认设置');
        _currentSettings = AirPlaySettings();
        await _saveSettings(); // 保存默认设置
      }

      _notifyListeners();
    } catch (e) {
      Log.e('SettingsService', '加载设置失败，使用默认设置', e);
      _currentSettings = AirPlaySettings();
    }
  }

  Future<void> _saveSettings() async {
    try {
      final settingsJson = jsonEncode(_currentSettings.toJson());
      await _prefs?.setString(_settingsKey, settingsJson);

      Log.d('SettingsService', '设置已保存');
    } catch (e) {
      Log.e('SettingsService', '保存设置失败', e);
    }
  }

  void _notifyListeners() {
    if (!_settingsController.isClosed) {
      _settingsController.add(_currentSettings);
    }
  }

  // 更新设置的通用方法
  Future<void> updateSettings(AirPlaySettings newSettings) async {
    _currentSettings = newSettings;
    await _saveSettings();
    _notifyListeners();

    Log.i('SettingsService', '设置已更新');
  }

  // 视频设置更新
  Future<void> updateVideoQuality(VideoQuality quality) async {
    int? videoBitrate;
    int? videoFramerate;

    // 根据质量预设自动调整其他参数
    switch (quality) {
      case VideoQuality.low:
        videoBitrate = 2000;
        videoFramerate = 30;
        break;
      case VideoQuality.medium:
        videoBitrate = 5000;
        videoFramerate = 30;
        break;
      case VideoQuality.high:
        videoBitrate = 8000;
        videoFramerate = 60;
        break;
      case VideoQuality.ultra:
        videoBitrate = 15000;
        videoFramerate = 30;
        break;
      case VideoQuality.auto:
        // 保持当前设置，由系统自动调整
        break;
    }

    final newSettings = _currentSettings.copyWith(
      videoQuality: quality,
      videoBitrate: videoBitrate,
      videoFramerate: videoFramerate,
    );

    await updateSettings(newSettings);
  }

  Future<void> updateAudioQuality(AudioQuality quality) async {
    int? audioBitrate;
    int? audioSampleRate;
    String? audioCodec;

    // 根据质量预设自动调整其他参数
    switch (quality) {
      case AudioQuality.low:
        audioBitrate = 128;
        audioSampleRate = 16000;
        break;
      case AudioQuality.medium:
        audioBitrate = 256;
        audioSampleRate = 44100;
        break;
      case AudioQuality.high:
        audioBitrate = 320;
        audioSampleRate = 48000;
        break;
      case AudioQuality.lossless:
        audioBitrate = 1411; // CD质量
        audioSampleRate = 48000;
        audioCodec = 'alac';
        break;
    }

    final newSettings = _currentSettings.copyWith(
      audioQuality: quality,
      audioBitrate: audioBitrate,
      audioSampleRate: audioSampleRate,
      audioCodec: audioCodec,
    );

    await updateSettings(newSettings);
  }

  Future<void> updatePerformanceMode(PerformanceMode mode) async {
    bool? hardwareAcceleration;
    int? bufferSize;
    bool? thermalThrottling;
    bool? backgroundProcessing;
    bool? lowLatencyMode;

    // 根据性能模式调整其他设置
    switch (mode) {
      case PerformanceMode.powersave:
        hardwareAcceleration = false;
        bufferSize = 15;
        thermalThrottling = true;
        backgroundProcessing = false;
        break;
      case PerformanceMode.balanced:
        hardwareAcceleration = true;
        bufferSize = 10;
        thermalThrottling = true;
        backgroundProcessing = false;
        break;
      case PerformanceMode.performance:
        hardwareAcceleration = true;
        bufferSize = 8;
        thermalThrottling = false;
        backgroundProcessing = true;
        break;
      case PerformanceMode.gaming:
        hardwareAcceleration = true;
        bufferSize = 5;
        lowLatencyMode = true;
        thermalThrottling = false;
        backgroundProcessing = true;
        break;
    }

    final newSettings = _currentSettings.copyWith(
      performanceMode: mode,
      hardwareAcceleration: hardwareAcceleration,
      bufferSize: bufferSize,
      thermalThrottling: thermalThrottling,
      backgroundProcessing: backgroundProcessing,
      lowLatencyMode: lowLatencyMode,
    );

    await updateSettings(newSettings);
  }

  // 调试模式设置
  Future<void> setDebugMode(bool enabled) async {
    final newSettings = _currentSettings.copyWith(debugMode: enabled);
    await updateSettings(newSettings);
  }

  // 详细日志设置
  Future<void> setVerboseMode(bool enabled) async {
    final newSettings = _currentSettings.copyWith(verboseLogging: enabled);
    await updateSettings(newSettings);
  }

  // 重置到默认设置
  Future<void> resetToDefaults() async {
    Log.i('SettingsService', '重置设置到默认值');

    _currentSettings = AirPlaySettings();
    await _saveSettings();
    _notifyListeners();
  }

  // 导出设置
  String exportSettings() {
    try {
      final exportData = {
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'settings': _currentSettings.toJson(),
      };

      return jsonEncode(exportData);
    } catch (e) {
      Log.e('SettingsService', '导出设置失败', e);
      rethrow;
    }
  }

  // 导入设置
  Future<bool> importSettings(String settingsJson) async {
    try {
      final importData = jsonDecode(settingsJson) as Map<String, dynamic>;

      if (importData['settings'] == null) {
        throw Exception('无效的设置文件格式');
      }

      final settings = AirPlaySettings.fromJson(importData['settings']);
      await updateSettings(settings);

      Log.i('SettingsService', '设置导入成功');
      return true;
    } catch (e) {
      Log.e('SettingsService', '导入设置失败', e);
      return false;
    }
  }

  // 验证设置合法性
  bool validateSettings(AirPlaySettings settings) {
    try {
      // 验证端口范围
      if (settings.httpPort < 1024 || settings.httpPort > 65535) return false;
      if (settings.rtspPort < 1024 || settings.rtspPort > 65535) return false;
      if (settings.httpPort == settings.rtspPort) return false;

      // 验证视频参数
      if (settings.videoBitrate < 100 || settings.videoBitrate > 50000) {
        return false;
      }
      if (settings.videoFramerate < 1 || settings.videoFramerate > 120) {
        return false;
      }

      // 验证音频参数
      if (settings.audioBitrate < 64 || settings.audioBitrate > 2000) {
        return false;
      }
      if (settings.audioSampleRate < 8000 || settings.audioSampleRate > 192000) {
        return false;
      }

      // 验证同步参数
      if (settings.syncThreshold < 10 || settings.syncThreshold > 200) {
        return false;
      }
      if (settings.jitterBufferSize < 10 || settings.jitterBufferSize > 500) {
        return false;
      }

      // 验证缓冲区大小
      if (settings.bufferSize < 1 || settings.bufferSize > 100) return false;

      // 验证亮度
      if (settings.brightness < 0.0 || settings.brightness > 1.0) return false;

      return true;
    } catch (e) {
      Log.e('SettingsService', '验证设置时出错', e);
      return false;
    }
  }

  // 获取推荐设置
  AirPlaySettings getRecommendedSettings() {
    // 基于设备性能返回推荐设置
    return AirPlaySettings(
      videoQuality: VideoQuality.high,
      audioQuality: AudioQuality.high,
      performanceMode: PerformanceMode.balanced,
      hardwareAcceleration: true,
      adaptiveSync: true,
      lowLatencyMode: false,
      thermalThrottling: true,
    );
  }

  void dispose() {
    Log.i('SettingsService', '清理设置服务资源');

    if (!_settingsController.isClosed) {
      _settingsController.close();
    }
  }
}

// 全局单例
final settingsService = SettingsService();
