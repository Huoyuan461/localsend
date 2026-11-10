import 'package:flutter/material.dart';

/// 3D黏土风按压动效：按下时整体下沉+缩小+阴影收缩，松开时弹性回弹。
/// 用于给按钮带来视频里那种"键帽式"立体按压质感。
class Pressable3D extends StatefulWidget {
  final Widget child;
  final double pressedScale;
  final double pressedOffsetY;

  const Pressable3D({
    required this.child,
    this.pressedScale = 0.96,
    this.pressedOffsetY = 3.0,
    super.key,
  });

  @override
  State<Pressable3D> createState() => _Pressable3DState();
}

class _Pressable3DState extends State<Pressable3D> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _offsetY;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 450),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _offsetY = Tween<double>(
      begin: 0.0,
      end: widget.pressedOffsetY,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent _) {
    _controller.forward();
  }

  void _onPointerUp(PointerUpEvent _) {
    // 松开时用弹性曲线回弹，带轻微过冲的"键帽感"
    _controller.animateBack(
      0.0,
      curve: Curves.elasticOut,
      duration: const Duration(milliseconds: 500),
    );
  }

  void _onPointerCancel(PointerCancelEvent _) {
    _controller.animateBack(
      0.0,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 用 Listener 只监听按压做动画，不拦截 child 自己的点击事件
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _offsetY.value),
            child: Transform.scale(scale: _scale.value, child: child),
          );
        },
        child: widget.child,
      ),
    );
  }
}
