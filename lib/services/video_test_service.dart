import 'dart:async';
import 'package:flutter/services.dart';
import 'logger_service.dart';

class VideoTestService {
  static const MethodChannel _channel = MethodChannel('com.airplay.padcast.receiver/video_decoder');
  
  bool _isRunning = false;
  Timer? _testTimer;
  
  bool get isRunning => _isRunning;
  
  Future<void> startTestPattern() async {
    if (_isRunning) return;
    
    try {
      Log.i('VideoTestService', '开始视频测试模式');
      
      // 初始化解码器
      await _channel.invokeMethod('initialize', {
        'width': 1920,
        'height': 1080,
      });
      
      // 启动解码
      await _channel.invokeMethod('start');
      
      _isRunning = true;
      
      // 创建测试定时器，模拟视频帧
      _testTimer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
        _sendTestFrame();
      });
      
      Log.i('VideoTestService', '视频测试模式已启动 (30fps)');
    } catch (e, stackTrace) {
      Log.e('VideoTestService', '启动视频测试失败', e, stackTrace);
      rethrow;
    }
  }
  
  Future<void> stopTestPattern() async {
    if (!_isRunning) return;
    
    try {
      _testTimer?.cancel();
      _testTimer = null;
      
      await _channel.invokeMethod('stop');
      await _channel.invokeMethod('release');
      
      _isRunning = false;
      Log.i('VideoTestService', '视频测试模式已停止');
    } catch (e) {
      Log.e('VideoTestService', '停止视频测试失败', e);
    }
  }
  
  void _sendTestFrame() {
    try {
      // 创建一个简单的测试帧 (模拟H.264 NAL单元)
      final testFrame = _createTestH264Frame();
      
      _channel.invokeMethod('decode', {
        'data': testFrame,
      });
    } catch (e) {
      Log.e('VideoTestService', '发送测试帧失败', e);
    }
  }
  
  Uint8List _createTestH264Frame() {
    // 创建一个最小的H.264 NAL单元用于测试
    // 这是一个简化的实现，实际应用中需要真实的H.264数据
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final frameNumber = (timestamp / 33).round(); // 30fps
    
    // 创建一个包含颜色变化的测试模式
    final colors = [
      0xFF, 0x00, 0x00, // 红色
      0x00, 0xFF, 0x00, // 绿色  
      0x00, 0x00, 0xFF, // 蓝色
      0xFF, 0xFF, 0x00, // 黄色
    ];
    
    final colorIndex = (frameNumber ~/ 30) % colors.length;
    final color = colors[colorIndex];
    
    // 创建简单的测试数据 (不是真实的H.264)
    final testData = Uint8List.fromList([
      0x00, 0x00, 0x00, 0x01, // NAL起始码
      0x67, // SPS NAL单元类型
      color, color, color, // 测试颜色数据
      frameNumber & 0xFF, (frameNumber >> 8) & 0xFF, // 帧号
      0x00, 0x00, 0x00, 0x01, // 下一个NAL起始码
      0x68, // PPS NAL单元类型
      0x01, 0x02, 0x03, 0x04, // PPS数据
      0x00, 0x00, 0x00, 0x01, // 下一个NAL起始码
      0x65, // IDR帧NAL单元类型
      // 简化的帧数据
      ...List.generate(100, (i) => (i + frameNumber + color) & 0xFF),
    ]);
    
    return testData;
  }
  
  void dispose() {
    stopTestPattern();
  }
}

// 单例实例
final videoTestService = VideoTestService();