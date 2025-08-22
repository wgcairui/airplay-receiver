import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'logger_service.dart';

class AudioVideoFrame {
  final int id;
  final double timestamp;
  final List<int> data;
  final bool isVideo;
  
  const AudioVideoFrame({
    required this.id,
    required this.timestamp,
    required this.data,
    required this.isVideo,
  });
}

class SyncState {
  final double videoTimestamp;
  final double audioTimestamp;
  final double offset;
  final bool isInSync;
  
  const SyncState({
    required this.videoTimestamp,
    required this.audioTimestamp,
    required this.offset,
    required this.isInSync,
  });
  
  double get syncDifference => (videoTimestamp - audioTimestamp).abs();
}

class AudioVideoSyncService {
  static const double _syncThreshold = 40.0; // 40ms同步阈值
  static const double _maxSyncOffset = 100.0; // 最大同步偏移100ms
  static const int _bufferSize = 10; // 缓冲区大小
  static const int _jitterBufferSize = 20; // 抖动缓冲区大小
  static const double _adaptiveThreshold = 20.0; // 自适应调整阈值
  
  final StreamController<SyncState> _syncStateController = 
      StreamController<SyncState>.broadcast();
  
  Stream<SyncState> get syncStateStream => _syncStateController.stream;
  
  // 音视频帧缓冲区
  final Queue<AudioVideoFrame> _videoBuffer = Queue<AudioVideoFrame>();
  final Queue<AudioVideoFrame> _audioBuffer = Queue<AudioVideoFrame>();
  final Queue<AudioVideoFrame> _jitterVideoBuffer = Queue<AudioVideoFrame>();
  final Queue<AudioVideoFrame> _jitterAudioBuffer = Queue<AudioVideoFrame>();
  
  // 当前播放位置
  double _currentVideoTimestamp = 0.0;
  double _currentAudioTimestamp = 0.0;
  
  // 同步偏移量
  double _audioVideoOffset = 0.0;
  double _predictedOffset = 0.0;
  
  // 时钟恢复和PTS管理
  double _masterClock = 0.0;
  double _videoClock = 0.0;
  double _audioClock = 0.0;
  double _clockDrift = 0.0;
  
  // 自适应参数
  double _adaptiveSyncThreshold = _syncThreshold;
  final List<double> _syncHistory = [];
  final List<double> _jitterHistory = [];
  
  // 性能统计
  int _syncCorrectionCount = 0;
  double _averageLatency = 0.0;
  double _maxJitter = 0.0;
  double _minJitter = double.infinity;
  int _lipSyncErrors = 0;
  int _frameDrops = 0;
  
  Timer? _syncTimer;
  bool _isRunning = false;
  
  bool get isRunning => _isRunning;
  double get currentAudioVideoOffset => _audioVideoOffset;
  int get syncCorrectionCount => _syncCorrectionCount;
  double get averageLatency => _averageLatency;
  double get maxJitter => _maxJitter;
  double get minJitter => _minJitter == double.infinity ? 0.0 : _minJitter;
  int get lipSyncErrors => _lipSyncErrors;
  int get frameDrops => _frameDrops;
  double get clockDrift => _clockDrift;
  double get adaptiveThreshold => _adaptiveSyncThreshold;
  
  void startSync() {
    if (_isRunning) return;
    
    _isRunning = true;
    
    // 初始化主时钟
    _masterClock = DateTime.now().millisecondsSinceEpoch.toDouble();
    _videoClock = _masterClock;
    _audioClock = _masterClock;
    
    _syncTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _processSyncFrame();
    });
    
    Log.i('AudioVideoSyncService', '高级音视频同步服务已启动');
  }
  
  void stopSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _isRunning = false;
    
    _videoBuffer.clear();
    _audioBuffer.clear();
    _jitterVideoBuffer.clear();
    _jitterAudioBuffer.clear();
    
    Log.i('AudioVideoSyncService', '音视频同步服务已停止');
  }
  
  void addVideoFrame(AudioVideoFrame frame) {
    if (!frame.isVideo) return;
    
    // 更新视频时钟
    _videoClock = frame.timestamp;
    
    // 添加到主缓冲区
    _videoBuffer.add(frame);
    _currentVideoTimestamp = frame.timestamp;
    
    // 抖动缓冲区管理
    _manageJitterBuffer(frame, true);
    
    // 保持缓冲区大小
    while (_videoBuffer.length > _bufferSize) {
      _videoBuffer.removeFirst();
    }
    
    // 计算抖动
    _calculateJitter(frame.timestamp, true);
  }
  
  void addAudioFrame(AudioVideoFrame frame) {
    if (frame.isVideo) return;
    
    // 更新音频时钟
    _audioClock = frame.timestamp;
    
    // 添加到主缓冲区
    _audioBuffer.add(frame);
    _currentAudioTimestamp = frame.timestamp;
    
    // 抖动缓冲区管理
    _manageJitterBuffer(frame, false);
    
    // 保持缓冲区大小
    while (_audioBuffer.length > _bufferSize) {
      _audioBuffer.removeFirst();
    }
    
    // 计算抖动
    _calculateJitter(frame.timestamp, false);
  }
  
  void _processSyncFrame() {
    if (_videoBuffer.isEmpty || _audioBuffer.isEmpty) return;
    
    // 更新主时钟
    _updateMasterClock();
    
    // 计算时钟漂移
    _calculateClockDrift();
    
    // 预测性同步调整
    _predictiveSync();
    
    // 计算当前音视频时间差
    final timeDifference = _currentVideoTimestamp - _currentAudioTimestamp;
    
    // 自适应阈值调整
    _updateAdaptiveThreshold(timeDifference.abs());
    
    // 检查是否需要同步调整
    if (timeDifference.abs() > _adaptiveSyncThreshold) {
      _performAdvancedSyncCorrection(timeDifference);
    }
    
    // 唇音同步检测
    _detectLipSyncError(timeDifference);
    
    // 更新同步状态
    final syncState = SyncState(
      videoTimestamp: _currentVideoTimestamp,
      audioTimestamp: _currentAudioTimestamp,
      offset: _audioVideoOffset,
      isInSync: timeDifference.abs() <= _adaptiveSyncThreshold,
    );
    
    _syncStateController.add(syncState);
    
    // 更新平均延迟和统计
    _updateAverageLatency(timeDifference.abs());
    _updateSyncHistory(timeDifference);
  }
  
  void _performAdvancedSyncCorrection(double timeDifference) {
    _syncCorrectionCount++;
    
    // 结合预测偏移量进行更精确的调整
    final totalOffset = timeDifference + _predictedOffset;
    
    if (totalOffset > 0) {
      // 视频超前，使用渐进式调整
      final adjustmentFactor = min(1.0, totalOffset / _maxSyncOffset);
      _audioVideoOffset = -totalOffset * adjustmentFactor;
      _audioVideoOffset = _audioVideoOffset.clamp(-_maxSyncOffset, _maxSyncOffset);
      
      Log.d('AudioVideoSyncService', 
        '视频超前 ${timeDifference.toStringAsFixed(1)}ms，预测偏移 ${_predictedOffset.toStringAsFixed(1)}ms，调整音频偏移 ${_audioVideoOffset.toStringAsFixed(1)}ms');
    } else {
      // 音频超前，使用渐进式调整
      final adjustmentFactor = min(1.0, (-totalOffset) / _maxSyncOffset);
      _audioVideoOffset = (-totalOffset) * adjustmentFactor;
      _audioVideoOffset = _audioVideoOffset.clamp(-_maxSyncOffset, _maxSyncOffset);
      
      Log.d('AudioVideoSyncService', 
        '音频超前 ${(-timeDifference).toStringAsFixed(1)}ms，预测偏移 ${(-_predictedOffset).toStringAsFixed(1)}ms，调整视频偏移 ${_audioVideoOffset.toStringAsFixed(1)}ms');
    }
  }
  
  void _updateAverageLatency(double currentLatency) {
    const alpha = 0.1; // 平滑系数
    _averageLatency = _averageLatency * (1 - alpha) + currentLatency * alpha;
  }
  
  // 获取同步建议的播放时间戳
  double getSyncedVideoTimestamp() {
    return _currentVideoTimestamp + _audioVideoOffset;
  }
  
  double getSyncedAudioTimestamp() {
    return _currentAudioTimestamp - _audioVideoOffset;
  }
  
  // 检查帧是否应该被播放
  bool shouldPlayVideoFrame(AudioVideoFrame frame) {
    if (!frame.isVideo) return false;
    
    final syncedTimestamp = getSyncedVideoTimestamp();
    
    return frame.timestamp <= syncedTimestamp;
  }
  
  bool shouldPlayAudioFrame(AudioVideoFrame frame) {
    if (frame.isVideo) return false;
    
    final syncedTimestamp = getSyncedAudioTimestamp();
    
    return frame.timestamp <= syncedTimestamp;
  }
  
  // 重置同步状态
  void resetSync() {
    _audioVideoOffset = 0.0;
    _predictedOffset = 0.0;
    _currentVideoTimestamp = 0.0;
    _currentAudioTimestamp = 0.0;
    _syncCorrectionCount = 0;
    _averageLatency = 0.0;
    _clockDrift = 0.0;
    _adaptiveSyncThreshold = _syncThreshold;
    _maxJitter = 0.0;
    _minJitter = double.infinity;
    _lipSyncErrors = 0;
    _frameDrops = 0;
    
    _videoBuffer.clear();
    _audioBuffer.clear();
    _jitterVideoBuffer.clear();
    _jitterAudioBuffer.clear();
    _syncHistory.clear();
    _jitterHistory.clear();
    
    // 重新初始化时钟
    _masterClock = DateTime.now().millisecondsSinceEpoch.toDouble();
    _videoClock = _masterClock;
    _audioClock = _masterClock;
    
    Log.i('AudioVideoSyncService', '音视频同步状态已重置');
  }
  
  // 获取增强的同步统计信息
  Map<String, dynamic> getSyncStats() {
    return {
      'is_in_sync': (_currentVideoTimestamp - _currentAudioTimestamp).abs() <= _adaptiveSyncThreshold,
      'sync_difference_ms': (_currentVideoTimestamp - _currentAudioTimestamp).abs(),
      'audio_video_offset_ms': _audioVideoOffset,
      'predicted_offset_ms': _predictedOffset,
      'sync_correction_count': _syncCorrectionCount,
      'average_latency_ms': _averageLatency,
      'video_buffer_size': _videoBuffer.length,
      'audio_buffer_size': _audioBuffer.length,
      'jitter_video_buffer_size': _jitterVideoBuffer.length,
      'jitter_audio_buffer_size': _jitterAudioBuffer.length,
      'current_video_timestamp': _currentVideoTimestamp,
      'current_audio_timestamp': _currentAudioTimestamp,
      'master_clock': _masterClock,
      'video_clock': _videoClock,
      'audio_clock': _audioClock,
      'clock_drift_ms': _clockDrift,
      'adaptive_threshold_ms': _adaptiveSyncThreshold,
      'max_jitter_ms': _maxJitter,
      'min_jitter_ms': minJitter,
      'lip_sync_errors': _lipSyncErrors,
      'frame_drops': _frameDrops,
      'sync_history_size': _syncHistory.length,
      'jitter_history_size': _jitterHistory.length,
    };
  }
  
  // ==================== 高级同步算法实现 ====================
  
  void _updateMasterClock() {
    final currentTime = DateTime.now().millisecondsSinceEpoch.toDouble();
    _masterClock = currentTime;
  }
  
  void _calculateClockDrift() {
    final expectedVideoTime = _masterClock;
    final expectedAudioTime = _masterClock;
    
    final videoDrift = _videoClock - expectedVideoTime;
    final audioDrift = _audioClock - expectedAudioTime;
    
    // 计算综合时钟漂移
    _clockDrift = (videoDrift + audioDrift) / 2;
    
    // 平滑处理避免抖动
    const driftAlpha = 0.05;
    _clockDrift = _clockDrift * driftAlpha + _clockDrift * (1 - driftAlpha);
  }
  
  void _predictiveSync() {
    if (_syncHistory.length < 3) return;
    
    // 基于历史数据预测下一帧的偏移量
    final recentHistory = _syncHistory.sublist(max(0, _syncHistory.length - 5));
    
    // 计算趋势
    double trend = 0.0;
    for (int i = 1; i < recentHistory.length; i++) {
      trend += recentHistory[i] - recentHistory[i - 1];
    }
    trend /= (recentHistory.length - 1);
    
    // 预测下一帧偏移量
    _predictedOffset = recentHistory.last + trend;
    
    // 限制预测范围，避免过度矫正
    _predictedOffset = _predictedOffset.clamp(-_maxSyncOffset / 2, _maxSyncOffset / 2);
  }
  
  void _updateAdaptiveThreshold(double currentDifference) {
    // 根据抖动历史动态调整同步阈值
    if (_jitterHistory.length < 5) return;
    
    final recentJitter = _jitterHistory.sublist(max(0, _jitterHistory.length - 10));
    final avgJitter = recentJitter.reduce((a, b) => a + b) / recentJitter.length;
    
    // 根据网络抖动情况调整阈值
    if (avgJitter > 30.0) {
      // 高抖动环境，放宽阈值
      _adaptiveSyncThreshold = _syncThreshold * 1.5;
    } else if (avgJitter < 10.0) {
      // 低抖动环境，严格阈值
      _adaptiveSyncThreshold = _syncThreshold * 0.7;
    } else {
      // 正常环境，使用默认阈值
      _adaptiveSyncThreshold = _syncThreshold;
    }
    
    _adaptiveSyncThreshold = _adaptiveSyncThreshold.clamp(_adaptiveThreshold, _syncThreshold * 2);
  }
  
  void _detectLipSyncError(double timeDifference) {
    // 检测严重的唇音同步错误 (>80ms被认为是明显的不同步)
    const lipSyncThreshold = 80.0;
    
    if (timeDifference.abs() > lipSyncThreshold) {
      _lipSyncErrors++;
      
      // 每10次唇音错误记录一次警告
      if (_lipSyncErrors % 10 == 0) {
        Log.w('AudioVideoSyncService', 
          '检测到唇音同步错误: ${timeDifference.toStringAsFixed(1)}ms，累计错误: $_lipSyncErrors次');
      }
    }
  }
  
  void _manageJitterBuffer(AudioVideoFrame frame, bool isVideo) {
    final buffer = isVideo ? _jitterVideoBuffer : _jitterAudioBuffer;
    
    // 添加到抖动缓冲区
    buffer.add(frame);
    
    // 保持抖动缓冲区大小
    while (buffer.length > _jitterBufferSize) {
      final droppedFrame = buffer.removeFirst();
      _frameDrops++;
      
      Log.d('AudioVideoSyncService', 
        '抖动缓冲区满，丢弃${isVideo ? '视频' : '音频'}帧，时间戳: ${droppedFrame.timestamp}');
    }
    
    // 排序以确保时间戳顺序（处理乱序帧）
    final sortedList = buffer.toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    buffer.clear();
    buffer.addAll(sortedList);
  }
  
  double? _lastVideoTimestamp;
  double? _lastAudioTimestamp;
  
  void _calculateJitter(double timestamp, bool isVideo) {
    
    final lastTimestamp = isVideo ? _lastVideoTimestamp : _lastAudioTimestamp;
    
    if (lastTimestamp != null) {
      final interval = timestamp - lastTimestamp;
      const expectedInterval = 33.33; // 30fps 预期间隔
      
      final jitter = (interval - expectedInterval).abs();
      
      // 更新抖动统计
      _jitterHistory.add(jitter);
      if (_jitterHistory.length > 100) {
        _jitterHistory.removeAt(0);
      }
      
      // 更新最大最小抖动
      _maxJitter = max(_maxJitter, jitter);
      if (_minJitter == double.infinity) {
        _minJitter = jitter;
      } else {
        _minJitter = min(_minJitter, jitter);
      }
    }
    
    if (isVideo) {
      _lastVideoTimestamp = timestamp;
    } else {
      _lastAudioTimestamp = timestamp;
    }
  }
  
  void _updateSyncHistory(double timeDifference) {
    _syncHistory.add(timeDifference);
    
    // 保持历史记录大小
    const maxHistorySize = 50;
    if (_syncHistory.length > maxHistorySize) {
      _syncHistory.removeAt(0);
    }
  }
  
  // 获取抖动缓冲区状态
  Map<String, dynamic> getJitterBufferStats() {
    return {
      'video_jitter_buffer_size': _jitterVideoBuffer.length,
      'audio_jitter_buffer_size': _jitterAudioBuffer.length,
      'video_jitter_buffer_utilization': _jitterVideoBuffer.length / _jitterBufferSize,
      'audio_jitter_buffer_utilization': _jitterAudioBuffer.length / _jitterBufferSize,
      'total_frame_drops': _frameDrops,
      'current_max_jitter_ms': _maxJitter,
      'current_min_jitter_ms': minJitter,
      'jitter_history_avg': _jitterHistory.isNotEmpty 
        ? _jitterHistory.reduce((a, b) => a + b) / _jitterHistory.length 
        : 0.0,
    };
  }
  
  // 获取时钟同步状态
  Map<String, dynamic> getClockSyncStats() {
    return {
      'master_clock': _masterClock,
      'video_clock': _videoClock,
      'audio_clock': _audioClock,
      'clock_drift_ms': _clockDrift,
      'video_clock_diff': _videoClock - _masterClock,
      'audio_clock_diff': _audioClock - _masterClock,
      'predicted_offset_ms': _predictedOffset,
      'adaptive_threshold_ms': _adaptiveSyncThreshold,
    };
  }
  
  void dispose() {
    stopSync();
    _syncStateController.close();
  }
}