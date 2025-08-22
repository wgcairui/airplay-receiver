import 'package:flutter/material.dart';

enum StatusType {
  success,
  warning,
  error,
  info,
  loading,
}

/// 状态指示器组件
class StatusIndicator extends StatefulWidget {
  final StatusType type;
  final String? text;
  final double size;
  final bool animate;
  final VoidCallback? onTap;

  const StatusIndicator({
    super.key,
    required this.type,
    this.text,
    this.size = 24,
    this.animate = true,
    this.onTap,
  });

  @override
  State<StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));

    if (widget.animate) {
      if (widget.type == StatusType.loading) {
        _animationController.repeat();
      } else if (widget.type == StatusType.warning ||
          widget.type == StatusType.error) {
        _animationController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getColorsForType(widget.type);
    final icon = _getIconForType(widget.type);

    Widget indicatorWidget = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: colors.borderColor,
          width: 2,
        ),
      ),
      child: Icon(
        icon,
        size: widget.size * 0.6,
        color: colors.iconColor,
      ),
    );

    // 应用动画
    if (widget.animate) {
      if (widget.type == StatusType.loading) {
        indicatorWidget = AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationAnimation.value * 2 * 3.14159,
              child: indicatorWidget,
            );
          },
        );
      } else if (widget.type == StatusType.warning ||
          widget.type == StatusType.error) {
        indicatorWidget = AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: indicatorWidget,
            );
          },
        );
      }
    }

    // 添加文本
    if (widget.text != null) {
      return GestureDetector(
        onTap: widget.onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            indicatorWidget,
            const SizedBox(width: 8),
            Text(
              widget.text!,
              style: TextStyle(
                color: colors.textColor,
                fontSize: widget.size * 0.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: indicatorWidget,
    );
  }

  _StatusColors _getColorsForType(StatusType type) {
    switch (type) {
      case StatusType.success:
        return _StatusColors(
          backgroundColor: Colors.green[50]!,
          borderColor: Colors.green[400]!,
          iconColor: Colors.green[600]!,
          textColor: Colors.green[800]!,
        );
      case StatusType.warning:
        return _StatusColors(
          backgroundColor: Colors.orange[50]!,
          borderColor: Colors.orange[400]!,
          iconColor: Colors.orange[600]!,
          textColor: Colors.orange[800]!,
        );
      case StatusType.error:
        return _StatusColors(
          backgroundColor: Colors.red[50]!,
          borderColor: Colors.red[400]!,
          iconColor: Colors.red[600]!,
          textColor: Colors.red[800]!,
        );
      case StatusType.info:
        return _StatusColors(
          backgroundColor: Colors.blue[50]!,
          borderColor: Colors.blue[400]!,
          iconColor: Colors.blue[600]!,
          textColor: Colors.blue[800]!,
        );
      case StatusType.loading:
        return _StatusColors(
          backgroundColor: Colors.grey[50]!,
          borderColor: Colors.grey[400]!,
          iconColor: Colors.grey[600]!,
          textColor: Colors.grey[800]!,
        );
    }
  }

  IconData _getIconForType(StatusType type) {
    switch (type) {
      case StatusType.success:
        return Icons.check;
      case StatusType.warning:
        return Icons.warning_amber;
      case StatusType.error:
        return Icons.error;
      case StatusType.info:
        return Icons.info;
      case StatusType.loading:
        return Icons.refresh;
    }
  }
}

class _StatusColors {
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;

  const _StatusColors({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
  });
}

/// 状态徽章组件
class StatusBadge extends StatelessWidget {
  final String text;
  final StatusType type;
  final bool isOutlined;
  final VoidCallback? onTap;

  const StatusBadge({
    super.key,
    required this.text,
    required this.type,
    this.isOutlined = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColorsForType(type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : colors.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.borderColor,
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colors.textColor,
          ),
        ),
      ),
    );
  }

  _StatusColors _getColorsForType(StatusType type) {
    switch (type) {
      case StatusType.success:
        return _StatusColors(
          backgroundColor: Colors.green[50]!,
          borderColor: Colors.green[300]!,
          iconColor: Colors.green[600]!,
          textColor: Colors.green[700]!,
        );
      case StatusType.warning:
        return _StatusColors(
          backgroundColor: Colors.orange[50]!,
          borderColor: Colors.orange[300]!,
          iconColor: Colors.orange[600]!,
          textColor: Colors.orange[700]!,
        );
      case StatusType.error:
        return _StatusColors(
          backgroundColor: Colors.red[50]!,
          borderColor: Colors.red[300]!,
          iconColor: Colors.red[600]!,
          textColor: Colors.red[700]!,
        );
      case StatusType.info:
        return _StatusColors(
          backgroundColor: Colors.blue[50]!,
          borderColor: Colors.blue[300]!,
          iconColor: Colors.blue[600]!,
          textColor: Colors.blue[700]!,
        );
      case StatusType.loading:
        return _StatusColors(
          backgroundColor: Colors.grey[50]!,
          borderColor: Colors.grey[300]!,
          iconColor: Colors.grey[600]!,
          textColor: Colors.grey[700]!,
        );
    }
  }
}

/// 进度指示器
class ProgressIndicator extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final String? label;
  final Color? color;
  final double height;
  final bool animate;

  const ProgressIndicator({
    super.key,
    required this.progress,
    this.label,
    this.color,
    this.height = 4,
    this.animate = true,
  });

  @override
  State<ProgressIndicator> createState() => _ProgressIndicatorState();
}

class _ProgressIndicatorState extends State<ProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    if (widget.animate) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(ProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.progress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ));

      if (widget.animate) {
        _animationController.reset();
        _animationController.forward();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(widget.progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(widget.height / 2),
          ),
          child: widget.animate
              ? AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progressAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius:
                              BorderRadius.circular(widget.height / 2),
                        ),
                      ),
                    );
                  },
                )
              : FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: widget.progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(widget.height / 2),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
