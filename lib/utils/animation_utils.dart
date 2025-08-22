import 'package:flutter/material.dart';

/// 动画工具类
class AnimationUtils {
  // 动画持续时间常量
  static const Duration fastDuration = Duration(milliseconds: 200);
  static const Duration normalDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 500);
  
  // 动画曲线常量
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve slideCurve = Curves.easeOut;
  
  /// 淡入淡出动画
  static Widget fadeIn({
    required Widget child,
    Duration duration = normalDuration,
    Curve curve = defaultCurve,
    double? initialOpacity,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: initialOpacity ?? 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
      child: child,
    );
  }
  
  /// 滑动进入动画
  static Widget slideIn({
    required Widget child,
    Duration duration = normalDuration,
    Curve curve = slideCurve,
    Offset begin = const Offset(0, 1),
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: begin, end: Offset.zero),
      duration: duration,
      curve: curve,
      builder: (context, offset, child) {
        return Transform.translate(
          offset: Offset(
            offset.dx * MediaQuery.of(context).size.width,
            offset.dy * MediaQuery.of(context).size.height,
          ),
          child: child,
        );
      },
      child: child,
    );
  }
  
  /// 缩放进入动画
  static Widget scaleIn({
    required Widget child,
    Duration duration = normalDuration,
    Curve curve = bounceCurve,
    double begin = 0.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: child,
    );
  }
  
  /// 旋转动画
  static Widget rotate({
    required Widget child,
    Duration duration = normalDuration,
    Curve curve = defaultCurve,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, rotation, child) {
        return Transform.rotate(
          angle: rotation * 2 * 3.14159,
          child: child,
        );
      },
      child: child,
    );
  }
  
  /// 组合动画：淡入 + 滑动
  static Widget fadeSlideIn({
    required Widget child,
    Duration duration = normalDuration,
    Offset slideBegin = const Offset(0, 0.3),
  }) {
    return fadeIn(
      duration: duration,
      child: slideIn(
        duration: duration,
        begin: slideBegin,
        child: child,
      ),
    );
  }
  
  /// 交错动画列表
  static List<Widget> staggeredList({
    required List<Widget> children,
    Duration staggerDuration = const Duration(milliseconds: 100),
    Duration animationDuration = normalDuration,
  }) {
    return children.asMap().entries.map((entry) {
      final child = entry.value;
      
      return AnimatedBuilder(
        animation: AlwaysStoppedAnimation(0),
        builder: (context, _) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: animationDuration,
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 50 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: child,
          );
        },
      );
    }).toList();
  }
}

/// 自定义动画组件
class AnimatedContainer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final VoidCallback? onComplete;
  
  const AnimatedContainer({
    super.key,
    required this.child,
    this.duration = AnimationUtils.normalDuration,
    this.curve = AnimationUtils.defaultCurve,
    this.onComplete,
  });
  
  @override
  State<AnimatedContainer> createState() => _AnimatedContainerState();
}

class _AnimatedContainerState extends State<AnimatedContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
    
    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// 弹性按钮动画
class BouncyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Duration duration;
  
  const BouncyButton({
    super.key,
    required this.child,
    this.onPressed,
    this.duration = const Duration(milliseconds: 150),
  });
  
  @override
  State<BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<BouncyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () {
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// 加载状态切换动画
class LoadingStateTransition extends StatelessWidget {
  final bool isLoading;
  final Widget loadingWidget;
  final Widget contentWidget;
  final Duration duration;
  
  const LoadingStateTransition({
    super.key,
    required this.isLoading,
    required this.loadingWidget,
    required this.contentWidget,
    this.duration = AnimationUtils.normalDuration,
  });
  
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: isLoading
          ? loadingWidget
          : contentWidget,
    );
  }
}

/// 页面转场动画
class PageTransitions {
  /// 滑动转场
  static PageRouteBuilder slideTransition({
    required Widget page,
    Duration duration = AnimationUtils.normalDuration,
    Offset begin = const Offset(1.0, 0.0),
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: begin,
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          )),
          child: child,
        );
      },
    );
  }
  
  /// 淡入转场
  static PageRouteBuilder fadeTransition({
    required Widget page,
    Duration duration = AnimationUtils.normalDuration,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
  
  /// 缩放转场
  static PageRouteBuilder scaleTransition({
    required Widget page,
    Duration duration = AnimationUtils.normalDuration,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          )),
          child: child,
        );
      },
    );
  }
}