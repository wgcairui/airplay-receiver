import 'dart:async';
import 'dart:collection';

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
  
  final StreamController<SyncState> _syncStateController = 
      StreamController<SyncState>.broadcast();
  
  Stream<SyncState> get syncStateStream => _syncStateController.stream;
  
  // 音视频帧缓冲区
  final Queue<AudioVideoFrame> _videoBuffer = Queue<AudioVideoFrame>();
  final Queue<AudioVideoFrame> _audioBuffer = Queue<AudioVideoFrame>();
  
  // 当前播放位置
  double _currentVideoTimestamp = 0.0;
  double _currentAudioTimestamp = 0.0;
  
  // 同步偏移量
  double _audioVideoOffset = 0.0;
  
  // 性能统计
  int _syncCorrectionCount = 0;
  double _averageLatency = 0.0;
  
  Timer? _syncTimer;
  bool _isRunning = false;
  
  bool get isRunning => _isRunning;
  double get currentAudioVideoOffset => _audioVideoOffset;
  int get syncCorrectionCount => _syncCorrectionCount;
  double get averageLatency => _averageLatency;
  
  void startSync() {
    if (_isRunning) return;
    
    _isRunning = true;
    _syncTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _processSyncFrame();
    });
    
    print('音视频同步服务已启动');
  }
  
  void stopSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _isRunning = false;
    
    _videoBuffer.clear();
    _audioBuffer.clear();
    
    print('音视频同步服务已停止');
  }
  
  void addVideoFrame(AudioVideoFrame frame) {
    if (!frame.isVideo) return;
    
    _videoBuffer.add(frame);
    _currentVideoTimestamp = frame.timestamp;
    
    // 保持缓冲区大小
    while (_videoBuffer.length > _bufferSize) {
      _videoBuffer.removeFirst();
    }
  }
  
  void addAudioFrame(AudioVideoFrame frame) {
    if (frame.isVideo) return;
    
    _audioBuffer.add(frame);
    _currentAudioTimestamp = frame.timestamp;
    
    // 保持缓冲区大小
    while (_audioBuffer.length > _bufferSize) {
      _audioBuffer.removeFirst();
    }
  }
  
  void _processSyncFrame() {
    if (_videoBuffer.isEmpty || _audioBuffer.isEmpty) return;
    
    // 计算当前音视频时间差
    final timeDifference = _currentVideoTimestamp - _currentAudioTimestamp;
    
    // 检查是否需要同步调整
    if (timeDifference.abs() > _syncThreshold) {
      _performSyncCorrection(timeDifference);
    }
    
    // 更新同步状态
    final syncState = SyncState(
      videoTimestamp: _currentVideoTimestamp,
      audioTimestamp: _currentAudioTimestamp,
      offset: _audioVideoOffset,
      isInSync: timeDifference.abs() <= _syncThreshold,
    );
    
    _syncStateController.add(syncState);
    
    // 更新平均延迟
    _updateAverageLatency(timeDifference.abs());
  }
  
  void _performSyncCorrection(double timeDifference) {
    _syncCorrectionCount++;
    
    if (timeDifference > 0) {
      // 视频超前，延迟视频播放或加速音频
      _audioVideoOffset = -timeDifference.clamp(-_maxSyncOffset, _maxSyncOffset);
      print('视频超前 ${timeDifference.toStringAsFixed(1)}ms，调整音频偏移');
    } else {
      // 音频超前，延迟音频播放或加速视频
      _audioVideoOffset = (-timeDifference).clamp(-_maxSyncOffset, _maxSyncOffset);
      print('音频超前 ${(-timeDifference).toStringAsFixed(1)}ms，调整视频偏移');
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
    _currentVideoTimestamp = 0.0;
    _currentAudioTimestamp = 0.0;
    _syncCorrectionCount = 0;
    _averageLatency = 0.0;
    
    _videoBuffer.clear();
    _audioBuffer.clear();
    
    print('音视频同步状态已重置');
  }
  
  // 获取同步统计信息
  Map<String, dynamic> getSyncStats() {
    return {
      'is_in_sync': (_currentVideoTimestamp - _currentAudioTimestamp).abs() <= _syncThreshold,
      'sync_difference_ms': (_currentVideoTimestamp - _currentAudioTimestamp).abs(),
      'audio_video_offset_ms': _audioVideoOffset,
      'sync_correction_count': _syncCorrectionCount,
      'average_latency_ms': _averageLatency,
      'video_buffer_size': _videoBuffer.length,
      'audio_buffer_size': _audioBuffer.length,
      'current_video_timestamp': _currentVideoTimestamp,
      'current_audio_timestamp': _currentAudioTimestamp,
    };
  }
  
  void dispose() {
    stopSync();
    _syncStateController.close();
  }
}