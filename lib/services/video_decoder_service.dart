import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'audio_video_sync_service.dart';

class VideoFrame {
  final Uint8List data;
  final int width;
  final int height;
  final double timestamp;
  final ui.Image? image;
  
  const VideoFrame({
    required this.data,
    required this.width,
    required this.height,
    required this.timestamp,
    this.image,
  });
}

class DecoderStats {
  final int framesDecoded;
  final int framesDropped;
  final double currentFPS;
  final double averageDecodeTime;
  final String codecType;
  
  const DecoderStats({
    required this.framesDecoded,
    required this.framesDropped,
    required this.currentFPS,
    required this.averageDecodeTime,
    required this.codecType,
  });
}

class VideoDecoderService {
  static const MethodChannel _channel = MethodChannel('com.airplay.padcast.receiver/video_decoder');
  static const EventChannel _eventChannel = EventChannel('com.airplay.padcast.receiver/video_events');
  
  final StreamController<VideoFrame> _frameController = 
      StreamController<VideoFrame>.broadcast();
  final StreamController<DecoderStats> _statsController = 
      StreamController<DecoderStats>.broadcast();
  
  Stream<VideoFrame> get frameStream => _frameController.stream;
  Stream<DecoderStats> get statsStream => _statsController.stream;
  
  AudioVideoSyncService? _syncService;
  StreamSubscription? _eventSubscription;
  
  // 解码器状态
  bool _isInitialized = false;
  bool _isDecoding = false;
  
  // 性能统计
  int _framesDecoded = 0;
  int _framesDropped = 0;
  double _currentFPS = 0.0;
  double _totalDecodeTime = 0.0;
  String _codecType = 'H.264';
  
  // FPS计算
  int _frameCount = 0;
  DateTime _lastFpsUpdate = DateTime.now();
  
  Timer? _statsTimer;
  
  bool get isInitialized => _isInitialized;
  bool get isDecoding => _isDecoding;
  DecoderStats get currentStats => DecoderStats(
    framesDecoded: _framesDecoded,
    framesDropped: _framesDropped,
    currentFPS: _currentFPS,
    averageDecodeTime: _totalDecodeTime / (_framesDecoded > 0 ? _framesDecoded : 1),
    codecType: _codecType,
  );
  
  void setSyncService(AudioVideoSyncService syncService) {
    _syncService = syncService;
  }
  
  Future<void> initialize({
    int width = 1920,
    int height = 1080,
    String codecType = 'video/avc', // H.264
  }) async {
    if (_isInitialized) return;
    
    try {
      // 初始化原生解码器
      await _channel.invokeMethod('initialize', {
        'width': width,
        'height': height,
      });
      
      // 监听原生事件
      _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
        _handleNativeEvent,
        onError: (error) {
          print('视频解码器事件监听错误: $error');
        },
      );
      
      _codecType = codecType == 'video/avc' ? 'H.264' : 'H.265';
      _isInitialized = true;
      
      // 启动统计定时器
      _startStatsTimer();
      
      print('视频解码器初始化完成: ${width}x$height $_codecType');
      
    } catch (e) {
      print('视频解码器初始化失败: $e');
      throw Exception('视频解码器初始化失败: $e');
    }
  }
  
  Future<void> startDecoding() async {
    if (!_isInitialized || _isDecoding) return;
    
    try {
      await _channel.invokeMethod('start');
      _isDecoding = true;
      
      print('视频解码器开始解码');
      
    } catch (e) {
      print('启动视频解码失败: $e');
      throw Exception('启动视频解码失败: $e');
    }
  }
  
  void _handleNativeEvent(dynamic event) {
    try {
      final Map<String, dynamic> eventData = Map<String, dynamic>.from(event);
      final String eventType = eventData['event'];
      final Map<String, dynamic> data = Map<String, dynamic>.from(eventData['data']);
      
      switch (eventType) {
        case 'frameDecoded':
          final videoTimestamp = (data['timestamp'] as int).toDouble();
          
          // 创建VideoFrame对象
          final frame = VideoFrame(
            width: 1920, // 从初始化参数获取
            height: 1080,
            timestamp: videoTimestamp,
            data: Uint8List(0), // 实际帧数据在原生端处理
          );
          
          _frameController.add(frame);
          _framesDecoded++;
          _updateFPS();
          
          // 通知音视频同步服务
          if (_syncService != null) {
            final syncFrame = AudioVideoFrame(
              id: _framesDecoded,
              timestamp: videoTimestamp,
              data: [],
              isVideo: true,
            );
            _syncService!.addVideoFrame(syncFrame);
          }
          break;
          
        case 'formatChanged':
          final width = data['width'] as int;
          final height = data['height'] as int;
          print('视频格式变更: ${width}x$height');
          break;
          
        case 'frameRate':
          final fps = data['fps'] as double;
          _currentFPS = fps;
          print('当前帧率: ${fps.toStringAsFixed(1)} FPS');
          break;
          
        case 'error':
          final message = data['message'] as String?;
          print('原生解码器错误: $message');
          break;
      }
    } catch (e) {
      print('处理原生事件失败: $e');
    }
  }
  
  Future<void> stopDecoding() async {
    if (!_isDecoding) return;
    
    try {
      await _channel.invokeMethod('stop');
      _isDecoding = false;
      
      print('视频解码器停止解码');
      
    } catch (e) {
      print('停止视频解码失败: $e');
    }
  }
  
  Future<void> decodeFrame(Uint8List frameData, double timestamp) async {
    if (!_isInitialized || !_isDecoding) return;
    
    try {
      final stopwatch = Stopwatch()..start();
      
      // 发送帧数据到原生解码器（异步处理）
      await _channel.invokeMethod('decode', {
        'data': frameData,
      });
      
      stopwatch.stop();
      final decodeTime = stopwatch.elapsedMilliseconds.toDouble();
      _totalDecodeTime += decodeTime;
      
      // 帧解码完成后会通过事件回调_handleNativeEvent处理
      
    } catch (e) {
      _framesDropped++;
      print('解码帧失败: $e');
    }
  }
  
  Future<VideoFrame?> decodeFrameSync(Uint8List frameData, double timestamp) async {
    if (!_isInitialized || !_isDecoding) return null;
    
    try {
      final stopwatch = Stopwatch()..start();
      
      final result = await _channel.invokeMethod('decodeFrameSync', {
        'data': frameData,
        'timestamp': timestamp,
      });
      
      stopwatch.stop();
      final decodeTime = stopwatch.elapsedMilliseconds.toDouble();
      _totalDecodeTime += decodeTime;
      
      if (result != null && result is Map) {
        _framesDecoded++;
        _updateFPS();
        
        return VideoFrame(
          data: Uint8List.fromList(result['data']),
          width: result['width'],
          height: result['height'],
          timestamp: timestamp,
        );
      } else {
        _framesDropped++;
        return null;
      }
      
    } catch (e) {
      _framesDropped++;
      print('同步解码帧失败: $e');
      return null;
    }
  }
  
  void _updateFPS() {
    _frameCount++;
    
    final now = DateTime.now();
    final elapsed = now.difference(_lastFpsUpdate);
    
    if (elapsed.inMilliseconds >= 1000) {
      _currentFPS = (_frameCount * 1000 / elapsed.inMilliseconds);
      _frameCount = 0;
      _lastFpsUpdate = now;
    }
  }
  
  void _startStatsTimer() {
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _statsController.add(currentStats);
    });
  }
  
  Future<void> flush() async {
    if (!_isInitialized) return;
    
    try {
      await _channel.invokeMethod('flush');
      print('视频解码器缓冲区已清空');
    } catch (e) {
      print('清空解码器缓冲区失败: $e');
    }
  }
  
  Future<void> reset() async {
    if (!_isInitialized) return;
    
    try {
      await _channel.invokeMethod('reset');
      
      // 重置统计数据
      _framesDecoded = 0;
      _framesDropped = 0;
      _currentFPS = 0.0;
      _totalDecodeTime = 0.0;
      _frameCount = 0;
      _lastFpsUpdate = DateTime.now();
      
      print('视频解码器已重置');
      
    } catch (e) {
      print('重置视频解码器失败: $e');
    }
  }
  
  // 获取解码器能力信息
  Future<Map<String, dynamic>> getDecoderCapabilities() async {
    try {
      final result = await _channel.invokeMethod('getCapabilities');
      return Map<String, dynamic>.from(result ?? {});
    } catch (e) {
      print('获取解码器能力失败: $e');
      return {};
    }
  }
  
  // 设置解码参数
  Future<void> setDecoderParams({
    int? maxFrameRate,
    int? bufferSize,
    bool? lowLatencyMode,
  }) async {
    try {
      await _channel.invokeMethod('setParams', {
        if (maxFrameRate != null) 'maxFrameRate': maxFrameRate,
        if (bufferSize != null) 'bufferSize': bufferSize,
        if (lowLatencyMode != null) 'lowLatencyMode': lowLatencyMode,
      });
      
      print('解码器参数设置完成');
      
    } on MissingPluginException {
      // 原生插件未实现，静默忽略
    } catch (e) {
      print('设置解码器参数失败: $e');
    }
  }
  
  Future<void> dispose() async {
    _statsTimer?.cancel();
    
    // 取消事件订阅
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    
    if (_isDecoding) {
      await stopDecoding();
    }
    
    if (_isInitialized) {
      try {
        await _channel.invokeMethod('release');
        _isInitialized = false;
      } catch (e) {
        print('销毁视频解码器失败: $e');
      }
    }
    
    await _frameController.close();
    await _statsController.close();
    
    print('视频解码器已销毁');
  }
  
  /// 更新设置
  void updateSettings(Map<String, dynamic> settings) {
    if (settings.containsKey('hardwareAcceleration')) {
      // 这里可以存储硬件加速设置
    }
    if (settings.containsKey('videoBitrate')) {
      // 这里可以存储视频比特率设置
    }
    if (settings.containsKey('videoFramerate')) {
      // 这里可以存储视频帧率设置
    }
    if (settings.containsKey('videoCodec')) {
      _codecType = settings['videoCodec'] == 'h265' ? 'H265' : 'H264';
    }
    
    print('视频解码器设置已更新: $settings');
  }
}