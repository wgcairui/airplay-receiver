import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import '../services/logger_service.dart';

class TestUtilities {
  static const List<String> _mockDeviceNames = [
    'MacBook Pro (13-inch)',
    'MacBook Air (M2)',
    'iMac (24-inch)',
    'Mac Studio',
    'iPhone 14 Pro',
    'iPad Pro (12.9-inch)',
    'Apple TV 4K',
  ];
  
  static const List<String> _mockIPAddresses = [
    '192.168.1.100',
    '192.168.1.101',
    '192.168.1.102',
    '192.168.1.103',
    '10.0.0.100',
    '10.0.0.101',
  ];
  
  /// 生成模拟的网络数据包
  static Uint8List generateMockNetworkPacket({
    int size = 1024,
    String? sourceIP,
    String? destIP,
    int? port,
  }) {
    final random = Random();
    final packet = Uint8List(size);
    
    // 填充随机数据
    for (int i = 0; i < size; i++) {
      packet[i] = random.nextInt(256);
    }
    
    // 模拟网络包头信息
    if (sourceIP != null) {
      final sourceBytes = _ipToBytes(sourceIP);
      packet.setRange(0, 4, sourceBytes);
    }
    
    if (destIP != null) {
      final destBytes = _ipToBytes(destIP);
      packet.setRange(4, 8, destBytes);
    }
    
    if (port != null) {
      packet[8] = (port >> 8) & 0xFF;
      packet[9] = port & 0xFF;
    }
    
    return packet;
  }
  
  /// 生成模拟的视频帧数据
  static Uint8List generateMockVideoFrame({
    int width = 1920,
    int height = 1080,
    String codec = 'h264',
    bool isKeyFrame = false,
  }) {
    final random = Random();
    
    // 估算帧大小（实际会根据内容和压缩率变化）
    final estimatedSize = isKeyFrame 
      ? (width * height * 0.1).round()  // 关键帧更大
      : (width * height * 0.03).round(); // 普通帧较小
    
    final frameData = Uint8List(estimatedSize);
    
    // 添加模拟的编码头信息
    if (codec == 'h264') {
      // H.264 NAL单元头
      frameData[0] = 0x00;
      frameData[1] = 0x00;
      frameData[2] = 0x00;
      frameData[3] = 0x01;
      frameData[4] = isKeyFrame ? 0x65 : 0x41; // IDR帧或P帧
    } else if (codec == 'h265') {
      // H.265 NAL单元头
      frameData[0] = 0x00;
      frameData[1] = 0x00;
      frameData[2] = 0x00;
      frameData[3] = 0x01;
      frameData[4] = isKeyFrame ? 0x26 : 0x02;
    }
    
    // 填充模拟的压缩数据
    for (int i = 5; i < frameData.length; i++) {
      frameData[i] = random.nextInt(256);
    }
    
    return frameData;
  }
  
  /// 生成模拟的音频帧数据
  static Uint8List generateMockAudioFrame({
    int sampleRate = 48000,
    int channels = 2,
    int bitsPerSample = 16,
    double durationMs = 20.0, // 20ms typical frame
    String codec = 'aac',
  }) {
    final samplesPerFrame = (sampleRate * durationMs / 1000).round();
    final bytesPerSample = bitsPerSample ~/ 8;
    final frameSize = samplesPerFrame * channels * bytesPerSample;
    
    final audioData = Uint8List(frameSize);
    final random = Random();
    
    if (codec == 'pcm') {
      // 生成PCM数据
      for (int i = 0; i < audioData.length; i += 2) {
        // 生成正弦波测试信号
        final sample = (sin(i * 0.01) * 32767).round();
        audioData[i] = sample & 0xFF;
        audioData[i + 1] = (sample >> 8) & 0xFF;
      }
    } else {
      // 生成压缩音频数据
      for (int i = 0; i < audioData.length; i++) {
        audioData[i] = random.nextInt(256);
      }
    }
    
    return audioData;
  }
  
  /// 模拟网络延迟
  static Future<void> simulateNetworkDelay({
    int minMs = 10,
    int maxMs = 50,
    double jitterPercent = 0.1,
  }) async {
    final random = Random();
    
    // 基础延迟
    final baseDelay = minMs + random.nextInt(maxMs - minMs);
    
    // 添加抖动
    final jitter = (baseDelay * jitterPercent * (random.nextDouble() - 0.5) * 2).round();
    final actualDelay = (baseDelay + jitter).clamp(1, maxMs * 2);
    
    await Future.delayed(Duration(milliseconds: actualDelay));
  }
  
  /// 模拟网络丢包
  static bool simulatePacketLoss({double lossRate = 0.01}) {
    final random = Random();
    return random.nextDouble() < lossRate;
  }
  
  /// 生成随机设备信息
  static Map<String, dynamic> generateMockDeviceInfo() {
    final random = Random();
    
    return {
      'name': _mockDeviceNames[random.nextInt(_mockDeviceNames.length)],
      'ip': _mockIPAddresses[random.nextInt(_mockIPAddresses.length)],
      'mac': _generateMockMacAddress(),
      'model': 'Test Device',
      'os_version': '${random.nextInt(5) + 10}.${random.nextInt(10)}.${random.nextInt(10)}',
      'airplay_version': '2.${random.nextInt(5)}',
      'features': ['video', 'audio', 'mirroring'],
      'resolution': ['1920x1080', '2560x1600', '3840x2160'][random.nextInt(3)],
      'refresh_rate': [60, 90, 120, 144][random.nextInt(4)],
    };
  }
  
  /// 生成模拟的性能数据
  static Map<String, dynamic> generateMockPerformanceData({
    double baseCpuUsage = 20.0,
    double baseMemoryUsage = 40.0,
    double baseLatency = 30.0,
  }) {
    final random = Random();
    
    // 添加随机变化
    final cpuVariation = (random.nextDouble() - 0.5) * 20;
    final memoryVariation = (random.nextDouble() - 0.5) * 15;
    final latencyVariation = (random.nextDouble() - 0.5) * 20;
    
    return {
      'cpu_usage_percent': (baseCpuUsage + cpuVariation).clamp(0.0, 100.0),
      'memory_usage_percent': (baseMemoryUsage + memoryVariation).clamp(0.0, 100.0),
      'memory_usage_mb': 150.0 + random.nextDouble() * 50,
      'available_memory_mb': 2000.0 + random.nextDouble() * 1000,
      'latency_ms': (baseLatency + latencyVariation).clamp(1.0, 200.0).round(),
      'frame_rate': [30, 60, 90, 120][random.nextInt(4)],
      'dropped_frames': random.nextInt(5),
      'total_frames': 1000 + random.nextInt(5000),
      'network_rx_mbps': random.nextDouble() * 100,
      'network_tx_kbps': random.nextDouble() * 1024,
      'gpu_usage_percent': random.nextDouble() * 60,
      'battery_level': 70.0 + random.nextDouble() * 30,
      'battery_temperature': 25.0 + random.nextDouble() * 15,
      'is_charging': random.nextBool(),
    };
  }
  
  /// 生成模拟的同步数据
  static Map<String, dynamic> generateMockSyncData({
    bool isInSync = true,
    double maxOffset = 40.0,
  }) {
    final random = Random();
    
    final syncOffset = isInSync 
      ? (random.nextDouble() - 0.5) * maxOffset
      : (random.nextDouble() - 0.5) * maxOffset * 3;
    
    return {
      'is_in_sync': syncOffset.abs() <= maxOffset,
      'sync_difference_ms': syncOffset.abs(),
      'audio_video_offset_ms': syncOffset,
      'predicted_offset_ms': syncOffset * 0.8,
      'sync_correction_count': random.nextInt(50),
      'average_latency_ms': 25.0 + random.nextDouble() * 25,
      'video_buffer_size': random.nextInt(10) + 5,
      'audio_buffer_size': random.nextInt(10) + 5,
      'jitter_video_buffer_size': random.nextInt(5),
      'jitter_audio_buffer_size': random.nextInt(5),
      'clock_drift_ms': (random.nextDouble() - 0.5) * 10,
      'adaptive_threshold_ms': 40.0 + random.nextDouble() * 20,
      'max_jitter_ms': random.nextDouble() * 15,
      'min_jitter_ms': random.nextDouble() * 5,
      'lip_sync_errors': random.nextInt(5),
      'frame_drops': random.nextInt(10),
    };
  }
  
  /// 模拟RTSP消息
  static Map<String, dynamic> generateMockRtspMessage({
    String method = 'SETUP',
    String uri = 'rtsp://192.168.1.100:7001/stream',
  }) {
    final random = Random();
    
    final headers = <String, String>{
      'CSeq': random.nextInt(1000).toString(),
      'User-Agent': 'AirPlay/2.0',
      'Content-Type': 'application/sdp',
      'Content-Length': random.nextInt(500).toString(),
    };
    
    if (method == 'SETUP') {
      headers['Transport'] = 'RTP/AVP/UDP;unicast;client_port=7000-7001';
    }
    
    return {
      'method': method,
      'uri': uri,
      'headers': headers,
      'body': method == 'SETUP' ? _generateMockSdp() : '',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }
  
  /// 创建测试用的定时器，模拟周期性事件
  static Timer createMockTimer({
    required Duration interval,
    required void Function() callback,
    int? maxCycles,
  }) {
    int cycleCount = 0;
    
    return Timer.periodic(interval, (timer) {
      if (maxCycles != null && cycleCount >= maxCycles) {
        timer.cancel();
        return;
      }
      
      callback();
      cycleCount++;
    });
  }
  
  /// 模拟异步操作，可能成功或失败
  static Future<T> simulateAsyncOperation<T>({
    required T Function() onSuccess,
    required Exception Function() onError,
    double successRate = 0.9,
    int minDelayMs = 100,
    int maxDelayMs = 1000,
  }) async {
    final random = Random();
    
    // 模拟操作延迟
    await simulateNetworkDelay(minMs: minDelayMs, maxMs: maxDelayMs);
    
    // 根据成功率决定结果
    if (random.nextDouble() < successRate) {
      return onSuccess();
    } else {
      throw onError();
    }
  }
  
  /// 测试断言工具
  static void assertEqual<T>(T actual, T expected, String message) {
    if (actual != expected) {
      throw AssertionError('$message: Expected $expected, but got $actual');
    }
  }
  
  static void assertTrue(bool condition, String message) {
    if (!condition) {
      throw AssertionError('$message: Condition is false');
    }
  }
  
  static void assertFalse(bool condition, String message) {
    if (condition) {
      throw AssertionError('$message: Condition is true');
    }
  }
  
  static void assertNotNull(dynamic value, String message) {
    if (value == null) {
      throw AssertionError('$message: Value is null');
    }
  }
  
  static void assertInRange<T extends num>(T value, T min, T max, String message) {
    if (value < min || value > max) {
      throw AssertionError('$message: $value is not in range [$min, $max]');
    }
  }
  
  /// 性能测试工具
  static Future<Duration> measureExecutionTime(Future<void> Function() operation) async {
    final stopwatch = Stopwatch()..start();
    await operation();
    stopwatch.stop();
    return stopwatch.elapsed;
  }
  
  static Future<Map<String, dynamic>> measureResourceUsage(
    Future<void> Function() operation,
    Future<Map<String, dynamic>> Function() getMetrics,
  ) async {
    final beforeMetrics = await getMetrics();
    final executionTime = await measureExecutionTime(operation);
    final afterMetrics = await getMetrics();
    
    return {
      'execution_time_ms': executionTime.inMilliseconds,
      'before_metrics': beforeMetrics,
      'after_metrics': afterMetrics,
      'cpu_delta': (afterMetrics['cpu_usage_percent'] ?? 0) - (beforeMetrics['cpu_usage_percent'] ?? 0),
      'memory_delta': (afterMetrics['memory_usage_mb'] ?? 0) - (beforeMetrics['memory_usage_mb'] ?? 0),
    };
  }
  
  /// 日志和调试工具
  static void logTestStep(String step, {Map<String, dynamic>? data}) {
    final timestamp = DateTime.now().toIso8601String();
    Log.d('TestUtilities', '[$timestamp] $step');
    
    if (data != null) {
      for (final entry in data.entries) {
        Log.d('TestUtilities', '  ${entry.key}: ${entry.value}');
      }
    }
  }
  
  static void logTestResult(String testName, bool passed, {String? error, Duration? duration}) {
    final status = passed ? 'PASSED' : 'FAILED';
    final durationText = duration != null ? ' (${duration.inMilliseconds}ms)' : '';
    
    Log.i('TestUtilities', '$testName: $status$durationText');
    
    if (!passed && error != null) {
      Log.e('TestUtilities', '$testName error: $error');
    }
  }
  
  // 私有工具方法
  static List<int> _ipToBytes(String ip) {
    return ip.split('.').map((part) => int.parse(part)).toList();
  }
  
  static String _generateMockMacAddress() {
    final random = Random();
    final parts = <String>[];
    
    for (int i = 0; i < 6; i++) {
      parts.add(random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    
    return parts.join(':');
  }
  
  static String _generateMockSdp() {
    return '''v=0
o=- 123456789 123456789 IN IP4 192.168.1.100
s=AirPlay Stream
c=IN IP4 192.168.1.100
t=0 0
m=video 7000 RTP/AVP 96
a=rtpmap:96 H264/90000
a=fmtp:96 profile-level-id=42e01e
m=audio 7002 RTP/AVP 97
a=rtpmap:97 MPEG4-GENERIC/44100/2
a=fmtp:97 streamtype=5;profile-level-id=2''';
  }
}

/// 测试数据生成器类
class TestDataGenerator {
  
  /// 生成测试用的视频流数据
  static Stream<Uint8List> generateVideoStream({
    Duration frameDuration = const Duration(milliseconds: 33), // 30fps
    int frameCount = 100,
  }) async* {
    for (int i = 0; i < frameCount; i++) {
      final isKeyFrame = i % 30 == 0; // 每30帧一个关键帧
      final frameData = TestUtilities.generateMockVideoFrame(
        isKeyFrame: isKeyFrame,
      );
      
      yield frameData;
      await Future.delayed(frameDuration);
    }
  }
  
  /// 生成测试用的音频流数据
  static Stream<Uint8List> generateAudioStream({
    Duration frameDuration = const Duration(milliseconds: 20), // 50fps
    int frameCount = 250,
  }) async* {
    for (int i = 0; i < frameCount; i++) {
      final frameData = TestUtilities.generateMockAudioFrame();
      
      yield frameData;
      await Future.delayed(frameDuration);
    }
  }
  
  /// 生成测试用的性能数据流
  static Stream<Map<String, dynamic>> generatePerformanceStream({
    Duration interval = const Duration(seconds: 1),
    int dataPoints = 60,
  }) async* {
    for (int i = 0; i < dataPoints; i++) {
      final data = TestUtilities.generateMockPerformanceData();
      
      yield data;
      await Future.delayed(interval);
    }
  }
  
  /// 生成渐变的负载数据（用于压力测试）
  static Stream<Map<String, dynamic>> generateLoadTestData({
    Duration interval = const Duration(seconds: 1),
    int dataPoints = 60,
    double maxCpuLoad = 90.0,
    double maxMemoryLoad = 85.0,
  }) async* {
    for (int i = 0; i < dataPoints; i++) {
      final progress = i / dataPoints;
      
      // 渐增的负载
      final cpuLoad = progress * maxCpuLoad;
      final memoryLoad = progress * maxMemoryLoad;
      
      final data = TestUtilities.generateMockPerformanceData(
        baseCpuUsage: cpuLoad,
        baseMemoryUsage: memoryLoad,
      );
      
      yield data;
      await Future.delayed(interval);
    }
  }
}