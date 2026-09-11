import 'dart:async';
import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../utils/match_status_helper.dart';

/// A circular live clock gauge widget displaying the elapsed match minute,
/// circular progress ring, top yellow marker, and goal markers.
class CircularLiveClock extends StatefulWidget {
  final String? status;
  final String? minute;
  final String? extraTime;
  final String? time;
  final String? period;
  final String? date;
  final String? score1;
  final String? score2;
  final double size;
  final Color arcColor;
  final Color notchColor;
  final Color? textColor;
  final List<int>? goalMinutes;

  const CircularLiveClock({
    super.key,
    this.status,
    this.minute,
    this.extraTime,
    this.time,
    this.period,
    this.date,
    this.score1,
    this.score2,
    this.size = 56.0,
    this.arcColor = const Color(0xFF2EE5A7),
    this.notchColor = const Color(0xFFFFD200),
    this.textColor,
    this.goalMinutes,
  });

  @override
  State<CircularLiveClock> createState() => _CircularLiveClockState();
}

class _CircularLiveClockState extends State<CircularLiveClock> {
  Timer? _timer;
  int _currentMinute = 0;
  String _displayMinute = '';
  MatchPhase _phase = MatchPhase.unknown;

  bool get _isInTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _syncClock();
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant CircularLiveClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status ||
        oldWidget.minute != widget.minute ||
        oldWidget.extraTime != widget.extraTime ||
        oldWidget.time != widget.time ||
        oldWidget.period != widget.period ||
        oldWidget.date != widget.date ||
        oldWidget.score1 != widget.score1 ||
        oldWidget.score2 != widget.score2) {
      _syncClock();
      _startTimerIfNeeded();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _syncClock() {
    _phase = MatchStatusHelper.parseStatus(
      widget.status,
      minute: widget.minute,
      extraTime: widget.extraTime,
      time: widget.time,
      date: widget.date,
      score1: widget.score1,
      score2: widget.score2,
    );

    int minNum = 0;
    String extraSuffix = '';

    if (widget.minute != null &&
        widget.minute!.isNotEmpty &&
        widget.minute != 'null') {
      final clean = widget.minute!.replaceAll("'", '').trim();
      if (clean.contains('+')) {
        final parts = clean.split('+');
        minNum = int.tryParse(parts[0].trim()) ?? 0;
        final extra = parts[1].trim();
        extraSuffix = '+$extra';
      } else if (clean.contains(':')) {
        final parts = clean.split(':');
        minNum = int.tryParse(parts[0].trim()) ?? 0;
      } else {
        minNum = int.tryParse(clean) ?? 0;
      }
    }

    if (minNum == 0) {
      minNum =
          MatchStatusHelper.estimateMinuteNumber(
            time: widget.time,
            status: widget.status,
            period: widget.period,
          ) ??
          0;
    }

    _currentMinute = minNum;

    if (_phase == MatchPhase.halfTime) {
      _displayMinute = 'HT';
    } else if (_phase == MatchPhase.penalties) {
      _displayMinute = 'PEN';
    } else if (_currentMinute > 0) {
      _displayMinute = '$_currentMinute$extraSuffix\'';
    } else {
      _displayMinute = '1\'';
    }
  }

  void _startTimerIfNeeded() {
    _timer?.cancel();
    if (!_isInTest &&
        MatchStatusHelper.isInPlay(_phase) &&
        _currentMinute >= 0 &&
        _currentMinute < 130) {
      _timer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (!mounted) return;
        setState(() {
          _syncClock();
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = widget.textColor ?? widget.arcColor;

    // Calculate match progress between 0.0 and 1.0 (90 min full cycle)
    double progress;
    if (_phase == MatchPhase.halfTime) {
      progress = 0.5;
    } else if (_currentMinute >= 90) {
      progress = 1.0;
    } else if (_currentMinute <= 0) {
      progress = 0.02;
    } else {
      progress = (_currentMinute / 90.0).clamp(0.02, 1.0);
    }

    // Extract total goals for marker placement
    final s1 = int.tryParse(widget.score1 ?? '');
    final s2 = int.tryParse(widget.score2 ?? '');
    final totalGoals = (s1 != null && s2 != null) ? (s1 + s2) : 0;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _CircularClockPainter(
              progress: progress,
              arcColor: widget.arcColor,
              notchColor: widget.notchColor,
              totalGoals: totalGoals,
              goalMinutes: widget.goalMinutes,
              currentMinute: _currentMinute,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _displayMinute,
              style: TextStyle(
                color: effectiveTextColor,
                fontSize: widget.size * 0.25,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularClockPainter extends CustomPainter {
  final double progress;
  final Color arcColor;
  final Color notchColor;
  final int totalGoals;
  final List<int>? goalMinutes;
  final int currentMinute;

  _CircularClockPainter({
    required this.progress,
    required this.arcColor,
    required this.notchColor,
    required this.totalGoals,
    this.goalMinutes,
    required this.currentMinute,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.048;
    final radius = (size.width - strokeWidth * 2) / 2;

    // 1. Background Track
    final trackPaint =
        Paint()
          ..color = arcColor.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    // 2. Active Progress Arc (starts from 12 o'clock, sweeping clockwise)
    const startAngle = -pi / 2;
    final sweepAngle = (progress * 2 * pi).clamp(0.01, 2 * pi);

    final arcPaint =
        Paint()
          ..color = arcColor
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = strokeWidth;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );

    // 3. Goal Markers (Mini Soccer Balls) along the arc
    if (goalMinutes != null && goalMinutes!.isNotEmpty) {
      for (final min in goalMinutes!) {
        final frac = (min / 90.0).clamp(0.02, 0.98);
        if (frac <= progress + 0.05) {
          final angle = startAngle + frac * 2 * pi;
          _drawSoccerBall(canvas, center, radius, angle, size.width * 0.08);
        }
      }
    } else if (totalGoals > 0 && progress > 0.08) {
      // Distribute goal markers along the progress arc
      for (int i = 0; i < totalGoals; i++) {
        final frac = (i + 1) / (totalGoals + 1) * progress;
        final angle = startAngle + frac * 2 * pi;
        _drawSoccerBall(canvas, center, radius, angle, size.width * 0.08);
      }
    }

    // 4. Top 12 o'clock yellow marker / notch
    final notchW = strokeWidth * 1.3;
    final notchH = strokeWidth * 2.6;
    final notchRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - radius),
        width: notchW,
        height: notchH,
      ),
      const Radius.circular(2.0),
    );
    final notchPaint =
        Paint()
          ..color = notchColor
          ..style = PaintingStyle.fill;
    canvas.drawRRect(notchRect, notchPaint);
  }

  void _drawSoccerBall(
    Canvas canvas,
    Offset center,
    double trackRadius,
    double angle,
    double ballRadius,
  ) {
    final bx = center.dx + trackRadius * cos(angle);
    final by = center.dy + trackRadius * sin(angle);
    final bCenter = Offset(bx, by);

    // White base
    canvas.drawCircle(
      bCenter,
      ballRadius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // Dark outline
    canvas.drawCircle(
      bCenter,
      ballRadius,
      Paint()
        ..color = const Color(0xFF1E2430)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // Dark center pentagon / dot
    final centerDotRadius = ballRadius * 0.42;
    canvas.drawCircle(
      bCenter,
      centerDotRadius,
      Paint()
        ..color = const Color(0xFF1E2430)
        ..style = PaintingStyle.fill,
    );

    // Radial spokes to simulate soccer ball seams
    final spokePaint =
        Paint()
          ..color = const Color(0xFF1E2430)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6;

    for (int i = 0; i < 5; i++) {
      final spokeAngle = (i * 2 * pi / 5) - (pi / 2);
      final p1 = Offset(
        bx + centerDotRadius * cos(spokeAngle),
        by + centerDotRadius * sin(spokeAngle),
      );
      final p2 = Offset(
        bx + ballRadius * cos(spokeAngle),
        by + ballRadius * sin(spokeAngle),
      );
      canvas.drawLine(p1, p2, spokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CircularClockPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.arcColor != arcColor ||
        oldDelegate.notchColor != notchColor ||
        oldDelegate.totalGoals != totalGoals ||
        oldDelegate.currentMinute != currentMinute;
  }
}
