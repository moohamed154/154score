import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class LivePulseBadge extends StatefulWidget {
  final String? minute;
  final bool showText;

  const LivePulseBadge({
    super.key,
    this.minute,
    this.showText = true,
  });

  @override
  State<LivePulseBadge> createState() => _LivePulseBadgeState();
}

class _LivePulseBadgeState extends State<LivePulseBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minuteText = widget.minute != null && widget.minute!.isNotEmpty
        ? widget.minute!
        : 'LIVE';

    return RepaintBoundary(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.liveRed.withOpacity(_animation.value),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.liveRed.withOpacity(_animation.value * 0.7),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              );
            },
          ),
          if (widget.showText) ...[
            const SizedBox(width: 5),
            Text(
              minuteText,
              style: AppTypography.getMinuteText(isLive: true),
            ),
          ],
        ],
      ),
    );
  }
}
