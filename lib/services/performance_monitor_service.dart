import 'dart:async';

class PerformanceMetrics {
  final double cpuUsagePercent;
  final double memoryUsageMB;
  final double batteryLevel;
  final int networkRxBytesPerSec;
  final int networkTxBytesPerSec;
  final int frameRate;
  final int latencyMs;
  final DateTime timestamp;
  
  const PerformanceMetrics({
    required this.cpuUsagePercent,
    required this.memoryUsageMB,
    required this.batteryLevel,
    required this.networkRxBytesPerSec,
    required this.networkTxBytesPerSec,
    required this.frameRate,
    required this.latencyMs,
    required this.timestamp,
  });
  
  @override
  String toString() {
    return 'PerformanceMetrics{'
        'CPU: ${cpuUsagePercent.toStringAsFixed(1)}%, '
        'Memory: ${memoryUsageMB.toStringAsFixed(1)}MB, '
        'FPS: $frameRate, '
        'Latency: ${latencyMs}ms'
        '}';
  }
}

class PerformanceMonitorService {
  Timer? _monitorTimer;
  final StreamController<PerformanceMetrics> _metricsController = 
      StreamController<PerformanceMetrics>.broadcast();
  
  Stream<PerformanceMetrics> get metricsStream => _metricsController.stream;
  
  PerformanceMetrics? _currentMetrics;
  PerformanceMetrics? get currentMetrics => _currentMetrics;
  
  bool _isMonitoring = false;
  bool get isMonitoring => _isMonitoring;
  
  // 性能统计
  int _frameCount = 0;
  int _currentFPS = 0;
  DateTime _lastFpsUpdate = DateTime.now();
  
  // 网络流量统计
  int _lastRxBytes = 0;
  DateTime _lastNetworkUpdate = DateTime.now();
  
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    
    // 每秒更新性能指标
    _monitorTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updatePerformanceMetrics();
    });
    
    print('性能监控服务已启动');
  }
  
  Future<void> stopMonitoring() async {
    _monitorTimer?.cancel();
    _monitorTimer = null;
    _isMonitoring = false;
    
    print('性能监控服务已停止');
  }
  
  void recordVideoFrame() {
    _frameCount++;
    
    final now = DateTime.now();
    final elapsed = now.difference(_lastFpsUpdate);
    
    if (elapsed.inMilliseconds >= 1000) {
      _currentFPS = (_frameCount * 1000 / elapsed.inMilliseconds).round();
      _frameCount = 0;
      _lastFpsUpdate = now;
    }
  }
  
  Future<void> _updatePerformanceMetrics() async {
    try {
      final metrics = PerformanceMetrics(
        cpuUsagePercent: await _getCPUUsage(),
        memoryUsageMB: await _getMemoryUsage(),
        batteryLevel: await _getBatteryLevel(),
        networkRxBytesPerSec: await _getNetworkRxRate(),
        networkTxBytesPerSec: await _getNetworkTxRate(),
        frameRate: _currentFPS,
        latencyMs: await _measureLatency(),
        timestamp: DateTime.now(),
      );
      
      _currentMetrics = metrics;
      _metricsController.add(metrics);
      
    } catch (e) {
      print('更新性能指标失败: $e');
    }
  }
  
  Future<double> _getCPUUsage() async {
    try {
      // 在Android上，可以通过读取/proc/stat获取CPU使用率
      // 这里提供一个简化的模拟实现
      
      // 模拟CPU使用率 (实际项目中需要读取系统文件)
      final random = DateTime.now().millisecondsSinceEpoch % 100;
      return (random / 100.0) * 30; // 模拟0-30%的CPU使用率
      
    } catch (e) {
      print('获取CPU使用率失败: $e');
      return 0.0;
    }
  }
  
  Future<double> _getMemoryUsage() async {
    try {
      // Android上可以通过ActivityManager获取内存使用情况
      // 这里提供一个简化的估算
      
      // 基础应用内存使用 (约100MB) + 视频缓冲区
      double baseMemory = 100.0;
      double videoBufferMemory = _currentFPS > 0 ? 50.0 : 0.0; // 视频流时增加50MB
      
      return baseMemory + videoBufferMemory;
      
    } catch (e) {
      print('获取内存使用率失败: $e');
      return 0.0;
    }
  }
  
  Future<double> _getBatteryLevel() async {
    try {
      // Android上可以通过BatteryManager获取电池信息
      // 这里返回模拟值
      return 85.0; // 模拟85%电量
      
    } catch (e) {
      print('获取电池电量失败: $e');
      return 100.0;
    }
  }
  
  Future<int> _getNetworkRxRate() async {
    try {
      // 可以通过读取/proc/net/dev获取网络流量
      // 这里提供简化实现
      
      final now = DateTime.now();
      final elapsed = now.difference(_lastNetworkUpdate).inMilliseconds;
      
      if (elapsed < 1000) return 0;
      
      // 模拟接收数据速率 (视频流约5MB/s)
      final currentRxBytes = _currentFPS > 0 ? 5 * 1024 * 1024 : 0; // 5MB/s when streaming
      final rate = (currentRxBytes - _lastRxBytes) * 1000 ~/ elapsed;
      
      _lastRxBytes = currentRxBytes;
      _lastNetworkUpdate = now;
      
      return rate.abs();
      
    } catch (e) {
      print('获取网络接收速率失败: $e');
      return 0;
    }
  }
  
  Future<int> _getNetworkTxRate() async {
    try {
      // 发送速率通常较小 (RTSP控制信令)
      return _currentFPS > 0 ? 1024 : 0; // 1KB/s when streaming
      
    } catch (e) {
      print('获取网络发送速率失败: $e');
      return 0;
    }
  }
  
  Future<int> _measureLatency() async {
    try {
      if (_currentFPS == 0) return 0;
      
      // 模拟端到端延迟测量
      // 实际项目中需要通过时间戳比较计算真实延迟
      final baseLatency = 30; // 基础网络延迟30ms
      final processingLatency = _currentFPS > 60 ? 10 : 20; // 处理延迟
      
      return baseLatency + processingLatency;
      
    } catch (e) {
      print('测量延迟失败: $e');
      return 0;
    }
  }
  
  // 性能分析方法
  bool isPerformanceGood() {
    if (_currentMetrics == null) return true;
    
    return _currentMetrics!.cpuUsagePercent < 50 &&
           _currentMetrics!.memoryUsageMB < 400 &&
           _currentMetrics!.latencyMs < 80;
  }
  
  String getPerformanceStatus() {
    if (_currentMetrics == null) return '未知';
    
    if (_currentMetrics!.cpuUsagePercent > 70) return 'CPU过载';
    if (_currentMetrics!.memoryUsageMB > 500) return '内存不足';
    if (_currentMetrics!.latencyMs > 100) return '延迟过高';
    
    return '正常';
  }
  
  Map<String, dynamic> getDetailedStats() {
    if (_currentMetrics == null) return {};
    
    return {
      'performance_status': getPerformanceStatus(),
      'cpu_usage_percent': _currentMetrics!.cpuUsagePercent,
      'memory_usage_mb': _currentMetrics!.memoryUsageMB,
      'battery_level': _currentMetrics!.batteryLevel,
      'frame_rate': _currentMetrics!.frameRate,
      'latency_ms': _currentMetrics!.latencyMs,
      'network_rx_mbps': _currentMetrics!.networkRxBytesPerSec / 1024 / 1024,
      'network_tx_kbps': _currentMetrics!.networkTxBytesPerSec / 1024,
      'timestamp': _currentMetrics!.timestamp.toIso8601String(),
    };
  }
  
  void dispose() {
    stopMonitoring();
    _metricsController.close();
  }
}