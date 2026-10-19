import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/app_colors.dart';

/// Premium sports match-highlight thumbnail placeholder for 154Score.
/// Displays an authentic football pitch backdrop with brand styling instead of third-party placeholders.
class VideoThumbnailPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final bool isDark;
  final bool showBadge;

  const VideoThumbnailPlaceholder({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12.0,
    required this.isDark,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  Color(0xFF0D1726),
                  Color(0xFF09291E),
                  Color(0xFF041A12),
                ]
              : const [
                  Color(0xFF1E293B),
                  Color(0xFF0D3D2E),
                  Color(0xFF052A1D),
                ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Tactical pitch pattern lines
          CustomPaint(
            painter: _SoccerPitchPatternPainter(
              lineColor: Colors.white.withValues(alpha: 0.07),
            ),
          ),

          // Top badge
          if (showBadge)
            PositionedDirectional(
              top: 10,
              end: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sports_soccer_rounded,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '154Score',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
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

class _SoccerPitchPatternPainter extends CustomPainter {
  final Color lineColor;

  const _SoccerPitchPatternPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Pitch border
    final borderRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(12, 12, size.width - 24, size.height - 24),
      const Radius.circular(8),
    );
    canvas.drawRRect(borderRect, paint);

    // Midfield line
    final midX = size.width / 2;
    canvas.drawLine(
      Offset(midX, 12),
      Offset(midX, size.height - 12),
      paint,
    );

    // Center circle
    final centerCircleRadius = (size.height * 0.22).clamp(16.0, 40.0);
    canvas.drawCircle(
      Offset(midX, size.height / 2),
      centerCircleRadius,
      paint,
    );

    // Left penalty box
    final boxW = size.width * 0.16;
    final boxH = size.height * 0.55;
    final boxTop = (size.height - boxH) / 2;
    canvas.drawRect(
      Rect.fromLTWH(12, boxTop, boxW, boxH),
      paint,
    );

    // Right penalty box
    canvas.drawRect(
      Rect.fromLTWH(size.width - 12 - boxW, boxTop, boxW, boxH),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SoccerPitchPatternPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}
