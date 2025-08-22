import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/airplay_controller.dart';
import '../widgets/video_renderer_widget.dart';
import '../services/video_decoder_service.dart';
import '../services/performance_monitor_service.dart';
import '../models/connection_state.dart' show ConnectionStatus;

class VideoStreamingView extends StatefulWidget {
  const VideoStreamingView({super.key});

  @override
  State<VideoStreamingView> createState() => _VideoStreamingViewState();
}

class _VideoStreamingViewState extends State<VideoStreamingView> {
  
  @override
  void initState() {
    super.initState();
    
    // 设置全屏和横屏
    _setupFullscreenMode();
  }
  
  @override
  void dispose() {
    // 恢复竖屏和系统UI
    _restoreNormalMode();
    super.dispose();
  }
  
  void _setupFullscreenMode() {
    // 设置横屏
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // 隐藏状态栏和导航栏
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );
  }
  
  void _restoreNormalMode() {
    // 恢复竖屏
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    
    // 显示系统UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<AirPlayController>(
        builder: (context, controller, child) {
          final connectionState = controller.connectionState;
          
          return Stack(
            children: [
              // 视频渲染器
              Positioned.fill(
                child: VideoRendererWidget(
                  decoderService: controller.isServiceRunning ? controller.videoDecoderService : null,
                  syncService: controller.syncService,
                  performanceService: controller.isServiceRunning ? controller.performanceMonitorService : null,
                  isPlaying: connectionState.isStreaming,
                  onTap: _handleVideoTap,
                ),
              ),
              
              // 连接状态覆盖层
              if (!connectionState.isStreaming)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.8),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getStatusIcon(connectionState.status),
                            size: 64,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            connectionState.statusText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getStatusDescription(connectionState.status),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                          
                          // 加载指示器
                          if (connectionState.status == ConnectionStatus.connecting ||
                              connectionState.status == ConnectionStatus.discovering)
                            const Padding(
                              padding: EdgeInsets.only(top: 24),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              // 退出按钮 (左上角)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: SafeArea(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              
              // 性能信息 (右上角)
              if (connectionState.isStreaming)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  right: 16,
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.videocam,
                            color: Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${connectionState.currentFPS ?? 0}fps',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.timer,
                            color: Colors.blue,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${connectionState.latencyMs ?? 0}ms',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
  
  void _handleVideoTap() {
    // 视频区域点击处理
    print('视频区域被点击');
  }
  
  IconData _getStatusIcon(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.disconnected:
        return Icons.cast;
      case ConnectionStatus.discovering:
        return Icons.search;
      case ConnectionStatus.connecting:
        return Icons.cast_connected;
      case ConnectionStatus.connected:
        return Icons.cast_connected;
      case ConnectionStatus.streaming:
        return Icons.play_circle_outline;
      case ConnectionStatus.error:
        return Icons.error_outline;
    }
  }
  
  String _getStatusDescription(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.disconnected:
        return '等待Mac设备连接\n在Mac上选择AirPlay投屏到OPPO Pad';
      case ConnectionStatus.discovering:
        return '正在广播设备信息\n请稍候...';
      case ConnectionStatus.connecting:
        return '正在建立连接\n请稍候...';
      case ConnectionStatus.connected:
        return '设备已连接\n准备接收投屏';
      case ConnectionStatus.streaming:
        return ''; // 不显示
      case ConnectionStatus.error:
        return '连接出现问题\n请检查网络设置';
    }
  }
}