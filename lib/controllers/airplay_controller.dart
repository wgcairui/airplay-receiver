import 'package:flutter/material.dart';
import '../services/airplay_service.dart';
import '../services/network_monitor_service.dart';
import '../services/performance_monitor_service.dart';
import '../services/audio_video_sync_service.dart';
import '../models/connection_state.dart' show AirPlayConnectionState;

class AirPlayController extends ChangeNotifier {
  final AirPlayService _airplayService = AirPlayService();
  
  AirPlayConnectionState get connectionState => _airplayService.currentState;
  AppNetworkInfo get networkInfo => _airplayService.networkMonitor.currentNetworkInfo;
  PerformanceMetrics? get performanceMetrics => _airplayService.performanceMonitor.currentMetrics;
  AudioVideoSyncService get syncService => _airplayService.syncService;
  
  // 访问解码器服务
  get videoDecoderService => _airplayService.decoderService;
  get audioDecoderService => _airplayService.audioDecoderService;
  get performanceMonitorService => _airplayService.performanceMonitor;
  
  bool _isServiceRunning = false;
  bool get isServiceRunning => _isServiceRunning;
  
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
    
    try {
      await _airplayService.startService();
      _isServiceRunning = true;
      notifyListeners();
    } catch (e) {
      print('启动AirPlay服务失败: $e');
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
    if (_isServiceRunning) {
      await stopAirPlayService();
    } else {
      await startAirPlayService();
    }
  }
  
  @override
  void dispose() {
    _airplayService.dispose();
    super.dispose();
  }
}