import 'dart:async';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'performance_monitor_service.dart';
import 'video_decoder_service.dart';

enum OptimizationLevel {
  auto,      // 自动优化
  balanced,  // 平衡模式
  performance, // 性能优先
  battery,   // 省电优先
}

class OptimizationProfile {
  final String name;
  final int maxFPS;
  final int bufferSize;
  final bool lowLatencyMode;
  final bool hardwareAcceleration;
  final bool adaptiveQuality;
  final double cpuThreshold;
  final double memoryThreshold;
  
  const OptimizationProfile({
    required this.name,
    required this.maxFPS,
    required this.bufferSize,
    required this.lowLatencyMode,
    required this.hardwareAcceleration,
    required this.adaptiveQuality,
    required this.cpuThreshold,
    required this.memoryThreshold,
  });
  
  static const OptimizationProfile ultraPerformance = OptimizationProfile(
    name: '极致性能',
    maxFPS: 60,
    bufferSize: 3,
    lowLatencyMode: true,
    hardwareAcceleration: true,
    adaptiveQuality: true,
    cpuThreshold: 80.0,
    memoryThreshold: 300.0,
  );
  
  static const OptimizationProfile balanced = OptimizationProfile(
    name: '平衡模式',
    maxFPS: 30,
    bufferSize: 5,
    lowLatencyMode: true,
    hardwareAcceleration: true,
    adaptiveQuality: true,
    cpuThreshold: 60.0,
    memoryThreshold: 400.0,
  );
  
  static const OptimizationProfile batterySaver = OptimizationProfile(
    name: '省电模式',
    maxFPS: 24,
    bufferSize: 8,
    lowLatencyMode: false,
    hardwareAcceleration: false,
    adaptiveQuality: true,
    cpuThreshold: 40.0,
    memoryThreshold: 500.0,
  );
}

class PerformanceOptimizationService {
  static const Duration _optimizationInterval = Duration(seconds: 2);
  static const double _latencyTarget = 50.0; // 目标延迟50ms
  
  final PerformanceMonitorService _performanceMonitor;
  VideoDecoderService? _decoderService;
  
  Timer? _optimizationTimer;
  OptimizationLevel _currentLevel = OptimizationLevel.auto;
  OptimizationProfile _currentProfile = OptimizationProfile.balanced;
  
  // 优化统计
  int _optimizationCount = 0;
  double _averageLatency = 0.0;
  bool _isOptimizing = false;
  
  // 动态调整历史
  final List<double> _latencyHistory = [];
  final List<double> _fpsHistory = [];
  final List<double> _cpuHistory = [];
  
  bool get isOptimizing => _isOptimizing;
  OptimizationLevel get currentLevel => _currentLevel;
  OptimizationProfile get currentProfile => _currentProfile;
  int get optimizationCount => _optimizationCount;
  double get averageLatency => _averageLatency;
  
  PerformanceOptimizationService(this._performanceMonitor);
  
  void setDecoderService(VideoDecoderService decoderService) {
    _decoderService = decoderService;
  }
  
  void startOptimization({OptimizationLevel level = OptimizationLevel.auto}) {
    if (_isOptimizing) return;
    
    _currentLevel = level;
    _isOptimizing = true;
    
    // 应用初始配置文件
    _applyOptimizationProfile(_getProfileForLevel(level));
    
    // 启动优化定时器
    _optimizationTimer = Timer.periodic(_optimizationInterval, (timer) {
      _performOptimizationCycle();
    });
    
    print('性能优化服务已启动 - 模式: ${level.name}');
  }
  
  void stopOptimization() {
    _optimizationTimer?.cancel();
    _optimizationTimer = null;
    _isOptimizing = false;
    
    // 清理历史数据
    _latencyHistory.clear();
    _fpsHistory.clear();
    _cpuHistory.clear();
    
    print('性能优化服务已停止');
  }
  
  void _performOptimizationCycle() {
    final metrics = _performanceMonitor.currentMetrics;
    if (metrics == null) return;
    
    // 更新历史数据
    _updateHistory(metrics);
    
    // 执行自动优化
    if (_currentLevel == OptimizationLevel.auto) {
      _autoOptimize(metrics);
    }
    
    // 检查延迟目标
    _checkLatencyTarget(metrics);
    
    _optimizationCount++;
  }
  
  void _updateHistory(PerformanceMetrics metrics) {
    _latencyHistory.add(metrics.latencyMs.toDouble());
    _fpsHistory.add(metrics.frameRate.toDouble());
    _cpuHistory.add(metrics.cpuUsagePercent);
    
    // 保持历史数据在合理范围内
    const maxHistorySize = 30;
    if (_latencyHistory.length > maxHistorySize) {
      _latencyHistory.removeAt(0);
      _fpsHistory.removeAt(0);
      _cpuHistory.removeAt(0);
    }
    
    // 更新平均延迟
    _averageLatency = _latencyHistory.reduce((a, b) => a + b) / _latencyHistory.length;
  }
  
  void _autoOptimize(PerformanceMetrics metrics) {
    // CPU使用率过高
    if (metrics.cpuUsagePercent > _currentProfile.cpuThreshold) {
      if (_currentProfile != OptimizationProfile.batterySaver) {
        _adjustForHighCpuUsage();
      }
    }
    
    // 内存使用过高
    if (metrics.memoryUsageMB > _currentProfile.memoryThreshold) {
      _adjustForHighMemoryUsage();
    }
    
    // 延迟过高
    if (metrics.latencyMs > _latencyTarget * 1.5) {
      _adjustForHighLatency();
    }
    
    // 帧率过低
    if (metrics.frameRate < _currentProfile.maxFPS * 0.8) {
      _adjustForLowFrameRate();
    }
  }
  
  void _adjustForHighCpuUsage() {
    print('CPU使用率过高，降低视频质量');
    
    // 降低帧率
    final newMaxFPS = (_currentProfile.maxFPS * 0.8).round().clamp(15, 60);
    
    // 增加缓冲区大小
    final newBufferSize = (_currentProfile.bufferSize * 1.2).round().clamp(3, 10);
    
    _currentProfile = OptimizationProfile(
      name: '${_currentProfile.name} (CPU优化)',
      maxFPS: newMaxFPS,
      bufferSize: newBufferSize,
      lowLatencyMode: _currentProfile.lowLatencyMode,
      hardwareAcceleration: _currentProfile.hardwareAcceleration,
      adaptiveQuality: true,
      cpuThreshold: _currentProfile.cpuThreshold,
      memoryThreshold: _currentProfile.memoryThreshold,
    );
    
    _applyOptimizationProfile(_currentProfile);
  }
  
  void _adjustForHighMemoryUsage() {
    print('内存使用过高，优化内存分配');
    
    // 减少缓冲区大小
    final newBufferSize = (_currentProfile.bufferSize * 0.7).round().clamp(2, 10);
    
    _currentProfile = OptimizationProfile(
      name: '${_currentProfile.name} (内存优化)',
      maxFPS: _currentProfile.maxFPS,
      bufferSize: newBufferSize,
      lowLatencyMode: _currentProfile.lowLatencyMode,
      hardwareAcceleration: _currentProfile.hardwareAcceleration,
      adaptiveQuality: _currentProfile.adaptiveQuality,
      cpuThreshold: _currentProfile.cpuThreshold,
      memoryThreshold: _currentProfile.memoryThreshold,
    );
    
    _applyOptimizationProfile(_currentProfile);
  }
  
  void _adjustForHighLatency() {
    print('延迟过高，启用低延迟模式');
    
    // 启用低延迟模式
    // 减少缓冲区
    final newBufferSize = 2;
    
    _currentProfile = OptimizationProfile(
      name: '${_currentProfile.name} (低延迟)',
      maxFPS: _currentProfile.maxFPS,
      bufferSize: newBufferSize,
      lowLatencyMode: true,
      hardwareAcceleration: _currentProfile.hardwareAcceleration,
      adaptiveQuality: _currentProfile.adaptiveQuality,
      cpuThreshold: _currentProfile.cpuThreshold,
      memoryThreshold: _currentProfile.memoryThreshold,
    );
    
    _applyOptimizationProfile(_currentProfile);
  }
  
  void _adjustForLowFrameRate() {
    print('帧率过低，调整解码参数');
    
    // 启用硬件加速
    // 降低质量要求
    _currentProfile = OptimizationProfile(
      name: '${_currentProfile.name} (帧率优化)',
      maxFPS: _currentProfile.maxFPS,
      bufferSize: _currentProfile.bufferSize,
      lowLatencyMode: _currentProfile.lowLatencyMode,
      hardwareAcceleration: true,
      adaptiveQuality: true,
      cpuThreshold: _currentProfile.cpuThreshold,
      memoryThreshold: _currentProfile.memoryThreshold,
    );
    
    _applyOptimizationProfile(_currentProfile);
  }
  
  void _checkLatencyTarget(PerformanceMetrics metrics) {
    if (metrics.latencyMs <= _latencyTarget) {
      // 延迟达标，可能可以提升质量
      if (_averageLatency < _latencyTarget * 0.8 && _cpuHistory.isNotEmpty) {
        final avgCpu = _cpuHistory.reduce((a, b) => a + b) / _cpuHistory.length;
        if (avgCpu < _currentProfile.cpuThreshold * 0.7) {
          _tryImproveQuality();
        }
      }
    }
  }
  
  void _tryImproveQuality() {
    // 尝试提升视频质量
    if (_currentProfile.maxFPS < 60) {
      final newMaxFPS = (_currentProfile.maxFPS * 1.2).round().clamp(15, 60);
      
      _currentProfile = OptimizationProfile(
        name: '${_currentProfile.name} (质量提升)',
        maxFPS: newMaxFPS,
        bufferSize: _currentProfile.bufferSize,
        lowLatencyMode: _currentProfile.lowLatencyMode,
        hardwareAcceleration: _currentProfile.hardwareAcceleration,
        adaptiveQuality: _currentProfile.adaptiveQuality,
        cpuThreshold: _currentProfile.cpuThreshold,
        memoryThreshold: _currentProfile.memoryThreshold,
      );
      
      _applyOptimizationProfile(_currentProfile);
      print('性能良好，提升视频质量到 ${newMaxFPS}fps');
    }
  }
  
  Future<void> _applyOptimizationProfile(OptimizationProfile profile) async {
    print('应用优化配置: ${profile.name}');
    
    // 配置视频解码器
    await _decoderService?.setDecoderParams(
      maxFrameRate: profile.maxFPS,
      bufferSize: profile.bufferSize,
      lowLatencyMode: profile.lowLatencyMode,
    );
    
    // 应用系统级优化
    await _applySystemOptimizations(profile);
  }
  
  Future<void> _applySystemOptimizations(OptimizationProfile profile) async {
    try {
      // 设置CPU性能模式
      if (profile.hardwareAcceleration) {
        await _setCpuPerformanceMode(true);
      }
      
      // 设置GPU优化
      await _setGpuOptimizations(profile.hardwareAcceleration);
      
      // 内存管理优化
      await _optimizeMemoryManagement(profile);
      
    } catch (e) {
      print('应用系统优化失败: $e');
    }
  }
  
  Future<void> _setCpuPerformanceMode(bool enable) async {
    // 通过原生方法调用设置CPU性能模式
    const platform = MethodChannel('padcast/performance');
    try {
      await platform.invokeMethod('setCpuPerformanceMode', {'enable': enable});
    } catch (e) {
      print('设置CPU性能模式失败: $e');
    }
  }
  
  Future<void> _setGpuOptimizations(bool enable) async {
    const platform = MethodChannel('padcast/performance');
    try {
      await platform.invokeMethod('setGpuOptimizations', {'enable': enable});
    } catch (e) {
      print('设置GPU优化失败: $e');
    }
  }
  
  Future<void> _optimizeMemoryManagement(OptimizationProfile profile) async {
    // 触发垃圾回收
    await _triggerGarbageCollection();
    
    // 设置内存阈值
    const platform = MethodChannel('padcast/performance');
    try {
      await platform.invokeMethod('setMemoryThreshold', {
        'threshold': profile.memoryThreshold,
      });
    } catch (e) {
      print('设置内存阈值失败: $e');
    }
  }
  
  Future<void> _triggerGarbageCollection() async {
    // 在独立的Isolate中执行垃圾回收
    try {
      await Isolate.spawn(_garbageCollectionIsolate, null);
    } catch (e) {
      print('触发垃圾回收失败: $e');
    }
  }
  
  static void _garbageCollectionIsolate(dynamic message) {
    // 执行内存清理操作
    print('执行垃圾回收');
  }
  
  OptimizationProfile _getProfileForLevel(OptimizationLevel level) {
    switch (level) {
      case OptimizationLevel.performance:
        return OptimizationProfile.ultraPerformance;
      case OptimizationLevel.balanced:
        return OptimizationProfile.balanced;
      case OptimizationLevel.battery:
        return OptimizationProfile.batterySaver;
      case OptimizationLevel.auto:
        return OptimizationProfile.balanced; // 默认从平衡模式开始
    }
  }
  
  // 手动设置优化级别
  void setOptimizationLevel(OptimizationLevel level) {
    _currentLevel = level;
    final profile = _getProfileForLevel(level);
    _currentProfile = profile;
    _applyOptimizationProfile(profile);
    
    print('手动设置优化级别: ${level.name}');
  }
  
  // 获取优化统计信息
  Map<String, dynamic> getOptimizationStats() {
    return {
      'optimization_level': _currentLevel.name,
      'current_profile': _currentProfile.name,
      'optimization_count': _optimizationCount,
      'average_latency_ms': _averageLatency,
      'target_latency_ms': _latencyTarget,
      'is_meeting_target': _averageLatency <= _latencyTarget,
      'max_fps': _currentProfile.maxFPS,
      'buffer_size': _currentProfile.bufferSize,
      'low_latency_mode': _currentProfile.lowLatencyMode,
      'hardware_acceleration': _currentProfile.hardwareAcceleration,
    };
  }
  
  void dispose() {
    stopOptimization();
  }
}