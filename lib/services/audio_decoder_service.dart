import 'dart:async';
import 'package:flutter/services.dart';
import 'audio_video_sync_service.dart';

class AudioFrame {
  final Uint8List data;
  final int sampleRate;
  final int channels;
  final double timestamp;
  final String codecType;
  
  const AudioFrame({
    required this.data,
    required this.sampleRate,
    required this.channels,
    required this.timestamp,
    required this.codecType,
  });
}

class AudioDecoderStats {
  final int framesDecoded;
  final int framesDropped;
  final double currentLatency;
  final double bufferHealth;
  final String codecType;
  
  const AudioDecoderStats({
    required this.framesDecoded,
    required this.framesDropped,
    required this.currentLatency,
    required this.bufferHealth,
    required this.codecType,
  });
}

class AudioDecoderService {
  static const MethodChannel _channel = MethodChannel('com.airplay.padcast.receiver/audio_decoder');
  static const EventChannel _eventChannel = EventChannel('com.airplay.padcast.receiver/audio_events');
  
  final StreamController<AudioFrame> _frameController = 
      StreamController<AudioFrame>.broadcast();
  final StreamController<AudioDecoderStats> _statsController = 
      StreamController<AudioDecoderStats>.broadcast();
  
  Stream<AudioFrame> get frameStream => _frameController.stream;
  Stream<AudioDecoderStats> get statsStream => _statsController.stream;
  
  AudioVideoSyncService? _syncService;
  StreamSubscription? _eventSubscription;
  
  // 解码器状态
  bool _isInitialized = false;
  bool _isDecoding = false;
  
  // 性能统计
  int _framesDecoded = 0;
  int _framesDropped = 0;
  double _currentLatency = 0.0;
  String _codecType = 'AAC';
  
  bool get isInitialized => _isInitialized;
  bool get isDecoding => _isDecoding;
  AudioDecoderStats get currentStats => AudioDecoderStats(
    framesDecoded: _framesDecoded,
    framesDropped: _framesDropped,
    currentLatency: _currentLatency,
    bufferHealth: _calculateBufferHealth(),
    codecType: _codecType,
  );
  
  void setSyncService(AudioVideoSyncService syncService) {
    _syncService = syncService;
  }
  
  Future<void> initialize({
    int sampleRate = 44100,
    int channels = 2,
    String codecType = 'audio/mp4a-latm', // AAC
  }) async {
    if (_isInitialized) return;
    
    try {
      // 初始化原生音频解码器
      await _channel.invokeMethod('initialize', {
        'sampleRate': sampleRate,
        'channels': channels,
        'codecType': codecType,
      });
      
      // 监听原生事件
      _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
        _handleNativeEvent,
        onError: (error) {
          print('音频解码器事件监听错误: $error');
        },
      );
      
      _codecType = codecType == 'audio/mp4a-latm' ? 'AAC' : 'ALAC';
      _isInitialized = true;
      
      print('音频解码器初始化完成: ${sampleRate}Hz ${channels}ch $_codecType');
      
    } catch (e) {
      print('音频解码器初始化失败: $e');
      throw Exception('音频解码器初始化失败: $e');
    }
  }
  
  Future<void> startDecoding() async {
    if (!_isInitialized || _isDecoding) return;
    
    try {
      await _channel.invokeMethod('start');
      _isDecoding = true;
      
      print('音频解码器开始解码');
      
    } catch (e) {
      print('启动音频解码失败: $e');
      throw Exception('启动音频解码失败: $e');
    }
  }
  
  void _handleNativeEvent(dynamic event) {
    try {
      final Map<String, dynamic> eventData = Map<String, dynamic>.from(event);
      final String eventType = eventData['event'];
      final Map<String, dynamic> data = Map<String, dynamic>.from(eventData['data']);
      
      switch (eventType) {
        case 'frameDecoded':
          final audioTimestamp = (data['timestamp'] as int).toDouble();
          final sampleRate = data['sampleRate'] as int;
          final channels = data['channels'] as int;
          
          // 创建AudioFrame对象
          final frame = AudioFrame(
            data: Uint8List(0), // 实际音频数据在原生端处理
            sampleRate: sampleRate,
            channels: channels,
            timestamp: audioTimestamp,
            codecType: _codecType,
          );
          
          _frameController.add(frame);
          _framesDecoded++;
          
          // 通知音视频同步服务
          if (_syncService != null) {
            final syncFrame = AudioVideoFrame(
              id: _framesDecoded,
              timestamp: audioTimestamp,
              data: [],
              isVideo: false,
            );
            _syncService!.addAudioFrame(syncFrame);
          }
          break;
          
        case 'formatChanged':
          final sampleRate = data['sampleRate'] as int;
          final channels = data['channels'] as int;
          print('音频格式变更: ${sampleRate}Hz ${channels}ch');
          break;
          
        case 'latencyUpdate':
          final latency = data['latency'] as double;
          _currentLatency = latency;
          break;
          
        case 'error':
          final message = data['message'] as String?;
          print('原生音频解码器错误: $message');
          break;
      }
    } catch (e) {
      print('处理音频原生事件失败: $e');
    }
  }
  
  Future<void> stopDecoding() async {
    if (!_isDecoding) return;
    
    try {
      await _channel.invokeMethod('stop');
      _isDecoding = false;
      
      print('音频解码器停止解码');
      
    } catch (e) {
      print('停止音频解码失败: $e');
    }
  }
  
  Future<void> decodeFrame(Uint8List frameData, double timestamp) async {
    if (!_isInitialized || !_isDecoding) return;
    
    try {
      // 发送帧数据到原生解码器（异步处理）
      await _channel.invokeMethod('decode', {
        'data': frameData,
      });
      
      // 帧解码完成后会通过事件回调_handleNativeEvent处理
      
    } catch (e) {
      _framesDropped++;
      print('解码音频帧失败: $e');
    }
  }
  
  double _calculateBufferHealth() {
    // 基于当前延迟计算缓冲区健康度
    const targetLatency = 50.0; // 目标延迟50ms
    
    if (_currentLatency <= targetLatency) {
      return 1.0;
    } else if (_currentLatency <= targetLatency * 2) {
      return 0.5;
    } else {
      return 0.2;
    }
  }
  
  // 设置音频输出参数
  Future<void> setAudioParams({
    double? volume,
    bool? muted,
    int? bufferSize,
  }) async {
    try {
      await _channel.invokeMethod('setParams', {
        if (volume != null) 'volume': volume,
        if (muted != null) 'muted': muted,
        if (bufferSize != null) 'bufferSize': bufferSize,
      });
      
      print('音频参数设置完成');
      
    } catch (e) {
      print('设置音频参数失败: $e');
    }
  }
  
  // 获取音频设备信息
  Future<Map<String, dynamic>> getAudioDeviceInfo() async {
    try {
      final result = await _channel.invokeMethod('getDeviceInfo');
      return Map<String, dynamic>.from(result ?? {});
    } catch (e) {
      print('获取音频设备信息失败: $e');
      return {};
    }
  }
  
  Future<void> flush() async {
    if (!_isInitialized) return;
    
    try {
      await _channel.invokeMethod('flush');
      print('音频解码器缓冲区已清空');
    } catch (e) {
      print('清空音频解码器缓冲区失败: $e');
    }
  }
  
  Future<void> reset() async {
    if (!_isInitialized) return;
    
    try {
      await _channel.invokeMethod('reset');
      
      // 重置统计数据
      _framesDecoded = 0;
      _framesDropped = 0;
      _currentLatency = 0.0;
      
      print('音频解码器已重置');
      
    } catch (e) {
      print('重置音频解码器失败: $e');
    }
  }
  
  Future<void> dispose() async {
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
        print('销毁音频解码器失败: $e');
      }
    }
    
    await _frameController.close();
    await _statsController.close();
    
    print('音频解码器已销毁');
  }
  
  /// 更新设置
  void updateSettings(Map<String, dynamic> settings) {
    if (settings.containsKey('audioBitrate')) {
      // 这里可以存储音频比特率设置，如果需要的话
    }
    if (settings.containsKey('audioSampleRate')) {
      // 这里可以存储音频采样率设置
    }
    if (settings.containsKey('audioCodec')) {
      _codecType = settings['audioCodec'] == 'alac' ? 'ALAC' : 'AAC';
    }
    if (settings.containsKey('audioEnhancement')) {
      // 这里可以存储音频增强设置
    }
    
    print('音频解码器设置已更新: $settings');
  }
}