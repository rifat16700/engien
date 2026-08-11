import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class SwipeToReplyWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;

  const SwipeToReplyWrapper({
    super.key,
    required this.child,
    required this.onReply,
  });

  @override
  State<SwipeToReplyWrapper> createState() => _SwipeToReplyWrapperState();
}

class _SwipeToReplyWrapperState extends State<SwipeToReplyWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragOffset = 0.0;
  bool _hapticFired = false;
  double _scale = 1.0;

  final double _maxDragThreshold = 60.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this);
    _controller.addListener(() {
      setState(() {
        _dragOffset = _controller.value;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanDown(DragDownDetails details) {
    _controller.stop();
    setState(() {
      _scale = 0.97;
      _hapticFired = false;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // Only allow swiping left
    if (details.delta.dx > 0 && _dragOffset >= 0) return;

    final screenWidth = MediaQuery.of(context).size.width;
    
    // Friction Formula: actual_drag = input_drag * (1 - (current_drag / max_screen_width)) * 0.55
    double dragDelta = details.delta.dx;
    double friction = (1 - (_dragOffset.abs() / screenWidth)) * 0.55;
    
    _dragOffset += dragDelta * friction;
    // clamp to only allow negative (left) drag
    if (_dragOffset > 0) _dragOffset = 0;

    if (_dragOffset.abs() >= _maxDragThreshold && !_hapticFired) {
      _hapticFired = true;
      HapticFeedback.lightImpact();
      // Optional: Trigger a micro-bounce on the icon
    }

    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _scale = 1.0;
    });

    if (_dragOffset.abs() >= _maxDragThreshold) {
      widget.onReply();
    }

    // Spring Description: mass: 1.0, stiffness: 400.0, damping: 22.0
    final spring = SpringDescription(
      mass: 1.0,
      stiffness: 400.0,
      damping: 22.0,
    );

    final simulation = SpringSimulation(
      spring,
      _dragOffset,
      0.0,
      details.velocity.pixelsPerSecond.dx,
    );

    _controller.animateWith(simulation);
  }

  void _onPanCancel() {
    setState(() {
      _scale = 1.0;
    });
    final spring = SpringDescription(
      mass: 1.0,
      stiffness: 400.0,
      damping: 22.0,
    );
    final simulation = SpringSimulation(spring, _dragOffset, 0.0, 0.0);
    _controller.animateWith(simulation);
  }

  @override
  Widget build(BuildContext context) {
    final opacity = (_dragOffset.abs() / 40.0).clamp(0.0, 1.0);
    // Rotate from -45 to 0 degrees based on drag
    // 45 degrees is pi/4 (0.785398 rad)
    final rotation = opacity * 0.785398 - 0.785398;
    
    // Icon bounce logic on threshold hit
    final iconScale = (_dragOffset.abs() >= _maxDragThreshold) ? 1.2 : 1.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanDown: _onPanDown,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onPanCancel: _onPanCancel,
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          // Reply Icon Layer
          if (_dragOffset < 0)
            Positioned(
              right: 16.0,
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: iconScale,
                  child: Transform.rotate(
                    angle: rotation,
                    child: const Icon(
                      Icons.reply_rounded,
                      color: AppTheme.tgBlue,
                    ),
                  ),
                ),
              ),
            ),
          
          // The Bubble Layer
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: AnimatedScale(
              scale: _scale,
              duration: const Duration(milliseconds: 50),
              curve: Curves.easeOut,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}
