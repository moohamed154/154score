import 'package:flutter/material.dart';

import '../constants/app_typography.dart';
import '../constants/app_colors.dart';

class AnimatedScoreText extends StatefulWidget {
  final String score;
  final bool isLarge;
  final bool isLive;

  const AnimatedScoreText({
    super.key,
    required this.score,
    this.isLarge = false,
    this.isLive = false,
  });

  @override
  State<AnimatedScoreText> createState() => _AnimatedScoreTextState();
}

class _AnimatedScoreTextState extends State<AnimatedScoreText>
    with SingleTickerProviderStateMixin {
  late AnimationController _highlightController;
  late Animation<Color?> _colorAnimation;
  String _previousScore = '';

  @override
  void initState() {
    super.initState();
    _previousScore = widget.score;
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedScoreText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score &&
        widget.score != '-' &&
        _previousScore != '-') {
      _previousScore = widget.score;
      _highlightController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    _colorAnimation = ColorTween(begin: AppColors.primary, end: defaultColor)
        .animate(
          CurvedAnimation(parent: _highlightController, curve: Curves.easeOut),
        );

    final baseStyle = widget.isLarge
        ? AppTypography.getScoreLarge(isDark: isDark)
        : AppTypography.getScoreMedium(isDark: isDark);

    return AnimatedBuilder(
      animation: _highlightController,
      builder: (context, child) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Text(
            widget.score,
            key: ValueKey<String>(widget.score),
            style: baseStyle.copyWith(
              color: _highlightController.isAnimating
                  ? _colorAnimation.value
                  : (widget.isLive ? AppColors.primaryLight : defaultColor),
            ),
          ),
        );
      },
    );
  }
}
