import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'logger_service.dart';

class AudioTestService {
  static const MethodChannel _channel =
      MethodChannel('com.airplay.padcast.receiver/audio_decoder');

  bool _isRunning = false;
  Timer? _testTimer;
  int _frameCounter = 0;

  bool get isRunning => _isRunning;

  Future<void> startTestTone() async {
    if (_isRunning) return;

    try {
      Log.i('AudioTestService', '开始音频测试模式');

      // 初始化音频解码器
      await _channel.invokeMethod('initialize', {
        'sampleRate': 44100,
        'channels': 2,
        'codecType': 'audio/mp4a-latm', // AAC
      });

      // 启动解码
      await _channel.invokeMethod('start');

      _isRunning = true;
      _frameCounter = 0;

      // 创建测试定时器，生成测试音频帧 (44.1kHz, 约23ms每帧)
      _testTimer = Timer.periodic(const Duration(milliseconds: 23), (timer) {
        _sendTestAudioFrame();
      });

      Log.i('AudioTestService', '音频测试模式已启动 (44.1kHz, Stereo)');
    } catch (e, stackTrace) {
      Log.e('AudioTestService', '启动音频测试失败', e, stackTrace);
      rethrow;
    }
  }

  Future<void> stopTestTone() async {
    if (!_isRunning) return;

    try {
      _testTimer?.cancel();
      _testTimer = null;

      await _channel.invokeMethod('stop');
      await _channel.invokeMethod('release');

      _isRunning = false;
      Log.i('AudioTestService', '音频测试模式已停止');
    } catch (e) {
      Log.e('AudioTestService', '停止音频测试失败', e);
    }
  }

  void _sendTestAudioFrame() {
    try {
      // 创建测试音频帧 (AAC格式模拟)
      final testFrame = _createTestAudioFrame();

      _channel.invokeMethod('decode', {
        'data': testFrame,
      });

      _frameCounter++;
    } catch (e) {
      Log.e('AudioTestService', '发送测试音频帧失败', e);
    }
  }

  Uint8List _createTestAudioFrame() {
    // 生成正弦波测试信号
    const sampleRate = 44100;
    const frameDuration = 0.023; // 23ms
    final samplesPerFrame = (sampleRate * frameDuration).round();

    // 生成440Hz测试音调 (左声道) 和 880Hz (右声道)
    final leftFreq = 440.0; // A4音符
    final rightFreq = 880.0; // A5音符

    final samples = <int>[];

    for (int i = 0; i < samplesPerFrame; i++) {
      final time = (_frameCounter * samplesPerFrame + i) / sampleRate;

      // 生成正弦波
      final leftSample = sin(2 * pi * leftFreq * time) * 0.3; // 降低音量
      final rightSample = sin(2 * pi * rightFreq * time) * 0.3;

      // 转换为16-bit PCM
      final leftPcm = (leftSample * 32767).round().clamp(-32768, 32767);
      final rightPcm = (rightSample * 32767).round().clamp(-32768, 32767);

      // 交替添加左右声道样本 (Little Endian)
      samples.add(leftPcm & 0xFF);
      samples.add((leftPcm >> 8) & 0xFF);
      samples.add(rightPcm & 0xFF);
      samples.add((rightPcm >> 8) & 0xFF);
    }

    // 创建简化的AAC帧头 (实际应用中需要真实的AAC编码)
    final aacHeader = [
      0xFF, 0xF9, // ADTS同步字和配置
      0x40, 0x80, // 配置信息
      0x00, 0x1F, // 帧长度 (示例)
      0xFC, // 其他配置
    ];

    return Uint8List.fromList([
      ...aacHeader,
      ...samples,
    ]);
  }

  void dispose() {
    stopTestTone();
  }
}

// 单例实例
final audioTestService = AudioTestService();
