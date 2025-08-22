import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

enum ToastType {
  success,
  error,
  warning,
  info,
}

/// Toast通知工具类
class ToastNotification {
  static OverlayEntry? _currentOverlay;
  
  /// 显示Toast通知
  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    String? title,
    VoidCallback? onTap,
  }) {
    _removeCurrentToast();
    
    final overlay = Overlay.of(context);
    _currentOverlay = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        type: type,
        title: title,
        onTap: onTap,
        onDismiss: _removeCurrentToast,
      ),
    );
    
    overlay.insert(_currentOverlay!);
    
    // 自动移除
    Future.delayed(duration, () {
      _removeCurrentToast();
    });
  }
  
  static void showSuccess(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      type: ToastType.success,
      title: title,
      duration: duration,
    );
  }
  
  static void showError(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      type: ToastType.error,
      title: title,
      duration: duration,
    );
  }
  
  static void showWarning(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      type: ToastType.warning,
      title: title,
      duration: duration,
    );
  }
  
  static void showInfo(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      type: ToastType.info,
      title: title,
      duration: duration,
    );
  }
  
  static void _removeCurrentToast() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final String? title;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;
  
  const _ToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
    this.title,
    this.onTap,
  });
  
  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _dismiss() async {
    await _animationController.reverse();
    widget.onDismiss();
  }
  
  @override
  Widget build(BuildContext context) {
    final colors = _getColorsForType(widget.type);
    final icon = _getIconForType(widget.type);
    
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                child: GestureDetector(
                  onTap: widget.onTap,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.backgroundColor,
                      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                      border: Border.all(color: colors.borderColor),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          color: colors.iconColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.title != null) ...[
                                Text(
                                  widget.title!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                              Text(
                                widget.message,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colors.textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _dismiss,
                          icon: Icon(
                            Icons.close,
                            color: colors.iconColor,
                            size: 20,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  _ToastColors _getColorsForType(ToastType type) {
    switch (type) {
      case ToastType.success:
        return _ToastColors(
          backgroundColor: Colors.green[50]!,
          borderColor: Colors.green[200]!,
          iconColor: Colors.green[600]!,
          textColor: Colors.green[800]!,
        );
      case ToastType.error:
        return _ToastColors(
          backgroundColor: Colors.red[50]!,
          borderColor: Colors.red[200]!,
          iconColor: Colors.red[600]!,
          textColor: Colors.red[800]!,
        );
      case ToastType.warning:
        return _ToastColors(
          backgroundColor: Colors.orange[50]!,
          borderColor: Colors.orange[200]!,
          iconColor: Colors.orange[600]!,
          textColor: Colors.orange[800]!,
        );
      case ToastType.info:
        return _ToastColors(
          backgroundColor: Colors.blue[50]!,
          borderColor: Colors.blue[200]!,
          iconColor: Colors.blue[600]!,
          textColor: Colors.blue[800]!,
        );
    }
  }
  
  IconData _getIconForType(ToastType type) {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle_outline;
      case ToastType.error:
        return Icons.error_outline;
      case ToastType.warning:
        return Icons.warning_amber_outlined;
      case ToastType.info:
        return Icons.info_outline;
    }
  }
}

class _ToastColors {
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;
  
  const _ToastColors({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
  });
}

/// SnackBar增强版本
class EnhancedSnackBar {
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    final colors = _getColorsForType(type);
    final icon = _getIconForType(type);
    
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: colors.backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onActionPressed ?? () {},
              )
            : null,
      ),
    );
  }
  
  static _SnackBarColors _getColorsForType(ToastType type) {
    switch (type) {
      case ToastType.success:
        return _SnackBarColors(backgroundColor: Colors.green[600]!);
      case ToastType.error:
        return _SnackBarColors(backgroundColor: Colors.red[600]!);
      case ToastType.warning:
        return _SnackBarColors(backgroundColor: Colors.orange[600]!);
      case ToastType.info:
        return _SnackBarColors(backgroundColor: Colors.blue[600]!);
    }
  }
  
  static IconData _getIconForType(ToastType type) {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle;
      case ToastType.error:
        return Icons.error;
      case ToastType.warning:
        return Icons.warning;
      case ToastType.info:
        return Icons.info;
    }
  }
}

class _SnackBarColors {
  final Color backgroundColor;
  
  const _SnackBarColors({
    required this.backgroundColor,
  });
}