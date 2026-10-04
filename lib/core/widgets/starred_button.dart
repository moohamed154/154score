import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';

/// A high-performance, 60/120 FPS micro-animated Star / Favorite button.
///
/// Features:
/// - Isolated render layer via [RepaintBoundary] to avoid repainting parent cards
/// - Bouncy scale & rotation spring animation ([Curves.easeOutBack]) on toggle
/// - Responsive tactile haptic feedback on tap
/// - Smooth cross-fade between outline and filled star icons with golden glow
class StarredButton extends StatefulWidget {
  final bool isStarred;
  final VoidCallback? onTap;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final EdgeInsetsGeometry padding;
  final String? tooltip;

  const StarredButton({
    super.key,
    required this.isStarred,
    this.onTap,
    this.size = 24.0,
    this.activeColor,
    this.inactiveColor,
    this.padding = const EdgeInsets.all(6.0),
    this.tooltip,
  });

  @override
  State<StarredButton> createState() => _StarredButtonState();
}

class _StarredButtonState extends State<StarredButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rotationAnimation;
  late bool _isStarred;

  @override
  void initState() {
    super.initState();
    _isStarred = widget.isStarred;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      value: widget.isStarred ? 1.0 : 0.0,
    );

    // Spring bounce: 0.8 -> 1.35 -> 1.0
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.78)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.78, end: 1.32)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.32, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
    ]).animate(_controller);

    // Subtle playful wobble
    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -0.12)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.12, end: 0.08)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.08, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant StarredButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isStarred != _isStarred) {
      setState(() {
        _isStarred = widget.isStarred;
      });
      if (_isStarred) {
        _controller.forward(from: 0.0);
      } else {
        _controller.reverse(from: 1.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    setState(() {
      _isStarred = !_isStarred;
    });
    if (_isStarred) {
      _controller.forward(from: 0.0);
    } else {
      _controller.reverse(from: 1.0);
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = widget.activeColor ?? AppColors.yellowCard;
    final inactiveColor = widget.inactiveColor ??
        (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted);

    final Widget child = RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Transform.scale(
            scale: _controller.isAnimating ? _scaleAnimation.value : 1.0,
            child: Transform.rotate(
              angle: _controller.isAnimating ? _rotationAnimation.value : 0.0,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: _isStarred
                    ? Icon(
                        Icons.star_rounded,
                        key: const ValueKey(true),
                        size: widget.size,
                        color: activeColor,
                        shadows: [
                          BoxShadow(
                            color: activeColor.withAlpha(120),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      )
                    : Icon(
                        Icons.star_border_rounded,
                        key: const ValueKey(false),
                        size: widget.size,
                        color: inactiveColor,
                      ),
              ),
            ),
          );
        },
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap != null ? _handleTap : null,
        borderRadius: BorderRadius.circular(widget.size + 12),
        splashColor: activeColor.withAlpha(40),
        highlightColor: activeColor.withAlpha(20),
        child: Padding(
          padding: widget.padding,
          child: widget.tooltip != null
              ? Tooltip(message: widget.tooltip!, child: child)
              : child,
        ),
      ),
    );
  }
}
