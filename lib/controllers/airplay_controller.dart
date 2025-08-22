import 'package:flutter/material.dart';
import '../services/airplay_service.dart';
import '../services/network_monitor_service.dart';
import '../services/performance_monitor_service.dart';
import '../services/audio_video_sync_service.dart';
import '../models/connection_state.dart' show AirPlayConnectionState;

class AirPlayController extends ChangeNotifier {
  final AirPlayService _airplayService = AirPlayService();

  AirPlayConnectionState get connectionState => _airplayService.currentState;
  AppNetworkInfo get networkInfo =>
      _airplayService.networkMonitor.currentNetworkInfo;
  PerformanceMetrics? get performanceMetrics =>
      _airplayService.performanceMonitor.currentMetrics;
  AudioVideoSyncService get syncService => _airplayService.syncService;

  // 访问解码器服务
  get videoDecoderService => _airplayService.decoderService;
  get audioDecoderService => _airplayService.audioDecoderService;
  get performanceMonitorService => _airplayService.performanceMonitor;

  bool _isServiceRunning = false;
  bool get isServiceRunning => _isServiceRunning;
  AirPlayService get airplayService => _airplayService;

  AirPlayController() {
    _airplayService.stateStream.listen((state) {
      notifyListeners();
    });

    _airplayService.networkMonitor.networkStream.listen((networkInfo) {
      notifyListeners();
    });

    _airplayService.performanceMonitor.metricsStream.listen((metrics) {
      notifyListeners();
    });

    _airplayService.syncService.syncStateStream.listen((syncState) {
      notifyListeners();
    });
  }

  Future<void> startAirPlayService() async {
    if (_isServiceRunning) return;

    print('AirPlayController: 开始启动AirPlay服务...');
    try {
      await _airplayService.startService();
      _isServiceRunning = true;
      print('AirPlayController: AirPlay服务启动成功，HTTP端口7100，RTSP端口7101');
      notifyListeners();
    } catch (e) {
      print('AirPlayController: 启动AirPlay服务失败: $e');
      rethrow;
    }
  }

  Future<void> stopAirPlayService() async {
    if (!_isServiceRunning) return;

    try {
      await _airplayService.stopService();
      _isServiceRunning = false;
      notifyListeners();
    } catch (e) {
      print('停止AirPlay服务失败: $e');
      rethrow;
    }
  }

  Future<void> toggleService() async {
    print('AirPlayController: toggleService 被调用，当前状态: $_isServiceRunning');
    
    // 防止在启动或停止过程中重复操作
    if (_airplayService.isStarting || _airplayService.isStopping) {
      print('AirPlayController: 服务正在启动/停止中，跳过操作');
      return;
    }

    if (_isServiceRunning) {
      await stopAirPlayService();
    } else {
      await startAirPlayService();
    }
  }

  @override
  void dispose() {
    // 异步清理服务，但不等待完成以避免阻塞dispose
    _airplayService.dispose().catchError((e) {
      print('清理AirPlay服务时出错: $e');
    });
    super.dispose();
  }
}
