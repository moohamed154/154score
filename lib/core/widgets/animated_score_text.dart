import 'package:material_ui/material_ui.dart';

import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class AnimatedScoreText extends StatelessWidget {
  final String score;
  final TextStyle? style;
  final bool isLarge;
  final bool isLive;
  final Duration duration;

  const AnimatedScoreText({
    super.key,
    required this.score,
    this.style,
    this.isLarge = false,
    this.isLive = false,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final resolvedStyle =
        style ??
        (isLarge
                ? AppTypography.getScoreLarge(isDark: isDark)
                : AppTypography.getScoreMedium(isDark: isDark))
            .copyWith(
              color: isLive
                  ? AppColors.liveRed
                  : (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary),
            );

    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Text(score, key: ValueKey<String>(score), style: resolvedStyle),
    );
  }
}
