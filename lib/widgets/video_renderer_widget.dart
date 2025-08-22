import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/video_decoder_service.dart';
import '../services/audio_video_sync_service.dart';
import '../services/performance_monitor_service.dart';
import 'native_video_texture.dart';

class VideoRendererWidget extends StatefulWidget {
  final VideoDecoderService? decoderService;
  final AudioVideoSyncService? syncService;
  final PerformanceMonitorService? performanceService;
  final bool isPlaying;
  final VoidCallback? onTap;
  
  const VideoRendererWidget({
    super.key,
    this.decoderService,
    this.syncService,
    this.performanceService,
    this.isPlaying = false,
    this.onTap,
  });

  @override
  State<VideoRendererWidget> createState() => _VideoRendererWidgetState();
}

class _VideoRendererWidgetState extends State<VideoRendererWidget> 
    with TickerProviderStateMixin {
  
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  
  // 视频流统计
  DateTime _lastFpsUpdate = DateTime.now();
  
  // 播放控制UI可见性
  bool _showControls = false;
  
  // 解码和同步状态
  DecoderStats? _decoderStats;
  SyncState? _syncState;
  PerformanceMetrics? _performanceMetrics;
  
  
  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // 监听解码器输出
    widget.decoderService?.frameStream.listen(_onVideoFrame);
    widget.decoderService?.statsStream.listen(_onDecoderStats);
    
    // 监听同步状态
    widget.syncService?.syncStateStream.listen(_onSyncState);
    
    // 监听性能指标
    widget.performanceService?.metricsStream.listen(_onPerformanceMetrics);
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
  
  void _onVideoFrame(VideoFrame frame) {
    _updateFPS();
    
    // 通知性能监控有新帧
    widget.performanceService?.recordVideoFrame();
  }
  
  void _onDecoderStats(DecoderStats stats) {
    setState(() {
      _decoderStats = stats;
    });
  }
  
  void _onSyncState(SyncState syncState) {
    setState(() {
      _syncState = syncState;
    });
  }
  
  void _onPerformanceMetrics(PerformanceMetrics metrics) {
    setState(() {
      _performanceMetrics = metrics;
    });
  }
  
  void _updateFPS() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastFpsUpdate);
    
    if (elapsed.inMilliseconds >= 1000) {
      setState(() {
        _lastFpsUpdate = now;
      });
    }
  }
  
  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    
    if (_showControls) {
      _fadeController.forward();
      // 3秒后自动隐藏控制栏
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _showControls) {
          _hideControls();
        }
      });
    } else {
      _hideControls();
    }
  }
  
  void _hideControls() {
    _fadeController.reverse();
    setState(() {
      _showControls = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          // 视频渲染区域
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _toggleControls();
                widget.onTap?.call();
              },
              child: _buildVideoRenderer(),
            ),
          ),
          
          // 加载指示器
          if (!widget.isPlaying)
            const Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      '等待视频流...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // 顶部状态栏
          AnimatedBuilder(
            animation: _fadeController,
            builder: (context, child) {
              return Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _fadeController.value,
                  child: _buildTopStatusBar(),
                ),
              );
            },
          ),
          
          // 底部控制栏
          AnimatedBuilder(
            animation: _fadeController,
            builder: (context, child) {
              return Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _fadeController.value,
                  child: _buildBottomControlBar(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildVideoRenderer() {
    if (!widget.isPlaying) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.tv,
                size: 64,
                color: Colors.white54,
              ),
              SizedBox(height: 16),
              Text(
                '等待视频流...',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // 使用原生纹理渲染器
    return VideoPlayerWidget(
      showControls: false,
      onTap: () {
        _toggleControls();
        widget.onTap?.call();
      },
    );
  }
  
  Widget _buildTopStatusBar() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        child: Row(
          children: [
            // 返回按钮
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
            ),
            
            const Spacer(),
            
            // 性能信息
            if (_decoderStats != null || _performanceMetrics != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_decoderStats != null) ...[
                      Text(
                        '${_decoderStats!.currentFPS.toStringAsFixed(1)}fps',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (_syncState != null) ...[
                      Icon(
                        _syncState!.isInSync ? Icons.sync : Icons.sync_problem,
                        color: _syncState!.isInSync ? Colors.green : Colors.red,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_syncState!.syncDifference.toStringAsFixed(0)}ms',
                        style: TextStyle(
                          color: _syncState!.isInSync ? Colors.green : Colors.red,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBottomControlBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 全屏按钮
            IconButton(
              onPressed: _toggleFullscreen,
              icon: const Icon(
                Icons.fullscreen,
                color: Colors.white,
                size: 32,
              ),
            ),
            
            const SizedBox(width: 24),
            
            // 设置按钮
            IconButton(
              onPressed: _showVideoSettings,
              icon: const Icon(
                Icons.settings,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _toggleFullscreen() {
    // 切换全屏模式
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
    
    // 隐藏系统UI
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
    );
  }
  
  void _showVideoSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '视频设置',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            // 解码器信息
            if (_decoderStats != null) ...[
              ListTile(
                leading: const Icon(Icons.video_library, color: Colors.white),
                title: const Text('解码器', style: TextStyle(color: Colors.white)),
                subtitle: Text('${_decoderStats!.codecType} - ${_decoderStats!.framesDecoded}帧', 
                              style: const TextStyle(color: Colors.grey)),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.white),
                title: const Text('帧率', style: TextStyle(color: Colors.white)),
                subtitle: Text('${_decoderStats!.currentFPS.toStringAsFixed(1)}fps', 
                              style: const TextStyle(color: Colors.grey)),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.timer, color: Colors.white),
                title: const Text('解码延迟', style: TextStyle(color: Colors.white)),
                subtitle: Text('${_decoderStats!.averageDecodeTime.toStringAsFixed(1)}ms', 
                              style: const TextStyle(color: Colors.grey)),
                onTap: () {},
              ),
            ],
            
            // 音视频同步信息
            if (_syncState != null) ...[
              ListTile(
                leading: Icon(
                  _syncState!.isInSync ? Icons.sync : Icons.sync_problem,
                  color: _syncState!.isInSync ? Colors.green : Colors.red,
                ),
                title: const Text('音视频同步', style: TextStyle(color: Colors.white)),
                subtitle: Text(
                  _syncState!.isInSync ? '同步正常' : '同步异常 (${_syncState!.syncDifference.toStringAsFixed(1)}ms)',
                  style: TextStyle(color: _syncState!.isInSync ? Colors.green : Colors.red),
                ),
                onTap: () {},
              ),
            ],
            
            // 性能信息
            if (_performanceMetrics != null) ...[
              ListTile(
                leading: const Icon(Icons.memory, color: Colors.white),
                title: const Text('系统资源', style: TextStyle(color: Colors.white)),
                subtitle: Text(
                  'CPU: ${_performanceMetrics!.cpuUsagePercent.toStringAsFixed(1)}% | '
                  'RAM: ${_performanceMetrics!.memoryUsageMB.toStringAsFixed(0)}MB',
                  style: const TextStyle(color: Colors.grey)
                ),
                onTap: () {},
              ),
            ],
          ],
        ),
      ),
    );
  }
}