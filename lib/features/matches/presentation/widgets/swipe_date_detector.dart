import 'package:material_ui/material_ui.dart';

/// Wraps [child] with a horizontal swipe detector that calls [onDateChanged]
/// with the adjacent [DateTime] when a deliberate swipe is detected.
///
/// Swipe RIGHT → previous day  |  Swipe LEFT → next day
///
/// [swipeVelocityThreshold] — minimum primary velocity (px/s) needed to
/// register as an intentional date-change swipe. Default 300.
class SwipeDateDetector extends StatelessWidget {
  const SwipeDateDetector({
    super.key,
    required this.currentDate,
    required this.onDateChanged,
    required this.child,
    this.swipeVelocityThreshold = 300.0,
  });

  final DateTime currentDate;
  final ValueChanged<DateTime> onDateChanged;
  final Widget child;
  final double swipeVelocityThreshold;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() < swipeVelocityThreshold) return;

        final isRtl = Directionality.of(context) == TextDirection.rtl;

        // In RTL layouts the physical swipe direction is mirrored
        final goForward = isRtl ? velocity > 0 : velocity < 0;

        final next = goForward
            ? currentDate.add(const Duration(days: 1)) // swipe left  → next
            : currentDate.subtract(
                const Duration(days: 1),
              ); // swipe right → prev

        onDateChanged(next);
      },
      child: child,
    );
  }
}
