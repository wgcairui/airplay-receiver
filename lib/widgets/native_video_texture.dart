import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NativeVideoTexture extends StatefulWidget {
  final double width;
  final double height;
  final bool autoStart;
  final VoidCallback? onTextureCreated;
  final Function(String)? onError;

  const NativeVideoTexture({
    super.key,
    this.width = 1920,
    this.height = 1080,
    this.autoStart = true,
    this.onTextureCreated,
    this.onError,
  });

  @override
  State<NativeVideoTexture> createState() => _NativeVideoTextureState();
}

class _NativeVideoTextureState extends State<NativeVideoTexture> {
  static const MethodChannel _channel =
      MethodChannel('com.airplay.padcast.receiver/video_decoder');
  static const EventChannel _eventChannel =
      EventChannel('com.airplay.padcast.receiver/video_events');

  int? _textureId;
  bool _isInitialized = false;
  StreamSubscription? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _initializeTexture();
    _listenToEvents();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _releaseTexture();
    super.dispose();
  }

  Future<void> _initializeTexture() async {
    try {
      // 创建纹理
      final textureId = await _channel.invokeMethod('createTexture');

      if (textureId != null && textureId != -1) {
        setState(() {
          _textureId = textureId;
          _isInitialized = true;
        });

        widget.onTextureCreated?.call();

        if (widget.autoStart) {
          await _startDecoding();
        }
      }
    } catch (e) {
      widget.onError?.call('Failed to create texture: $e');
    }
  }

  void _listenToEvents() {
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        if (event is Map) {
          final eventType = event['event'] as String?;
          final data = event['data'] as Map?;

          switch (eventType) {
            case 'frameAvailable':
              // 纹理有新帧可用，触发重绘
              if (mounted) {
                setState(() {});
              }
              break;
            case 'formatChanged':
              // 视频格式改变
              if (data != null) {
                final width = data['width'] as int?;
                final height = data['height'] as int?;
                print('Video format changed: ${width}x$height');
              }
              break;
            case 'error':
              final message = data?['message'] as String? ?? 'Unknown error';
              widget.onError?.call(message);
              break;
          }
        }
      },
      onError: (error) {
        widget.onError?.call('Event stream error: $error');
      },
    );
  }

  Future<void> _startDecoding() async {
    try {
      await _channel.invokeMethod('start');
    } catch (e) {
      widget.onError?.call('Failed to start decoding: $e');
    }
  }

  Future<void> _releaseTexture() async {
    try {
      await _channel.invokeMethod('release');
    } catch (e) {
      print('Error releasing texture: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _textureId == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                '初始化视频渲染器...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Texture(textureId: _textureId!),
    );
  }
}

// 便捷的视频播放器组件
class VideoPlayerWidget extends StatefulWidget {
  final double? width;
  final double? height;
  final bool showControls;
  final VoidCallback? onTap;

  const VideoPlayerWidget({
    super.key,
    this.width,
    this.height,
    this.showControls = true,
    this.onTap,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  bool _isPlaying = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = widget.width ?? size.width;
    final height = widget.height ?? size.height;

    return Container(
      width: width,
      height: height,
      color: Colors.black,
      child: Stack(
        children: [
          // 视频纹理
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onTap,
              child: NativeVideoTexture(
                width: width,
                height: height,
                onTextureCreated: () {
                  setState(() {
                    _isPlaying = true;
                    _errorMessage = null;
                  });
                },
                onError: (error) {
                  setState(() {
                    _errorMessage = error;
                    _isPlaying = false;
                  });
                },
              ),
            ),
          ),

          // 错误显示
          if (_errorMessage != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '视频播放错误',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 播放状态指示器
          if (!_isPlaying && _errorMessage == null)
            const Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      '等待视频流...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
