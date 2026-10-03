import 'dart:async';
import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../utils/live_clock_sync.dart';
import '../utils/match_status_helper.dart';

/// A circular live clock gauge widget displaying the elapsed match minute,
/// circular progress ring, top yellow marker, and goal markers.
class CircularLiveClock extends StatefulWidget {
  final String? matchId;
  final String? status;
  final String? statusCode;
  final String? minute;
  final String? extraTime;
  final String? time;
  final String? period;
  final String? date;
  final String? score1;
  final String? score2;
  final int? timestamp;
  final double size;
  final Color arcColor;
  final Color notchColor;
  final Color? textColor;
  final List<int>? goalMinutes;

  const CircularLiveClock({
    super.key,
    this.matchId,
    this.status,
    this.statusCode,
    this.minute,
    this.extraTime,
    this.time,
    this.period,
    this.date,
    this.score1,
    this.score2,
    this.timestamp,
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
  int _currentSecond = 0;
  int _elapsedExtraSeconds = 0;
  int _totalExtraMinutes = 0;
  String _displayMinute = '';
  String? _displayExtra;
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
    if (oldWidget.matchId != widget.matchId ||
        oldWidget.status != widget.status ||
        oldWidget.statusCode != widget.statusCode ||
        oldWidget.minute != widget.minute ||
        oldWidget.extraTime != widget.extraTime ||
        oldWidget.time != widget.time ||
        oldWidget.period != widget.period ||
        oldWidget.date != widget.date ||
        oldWidget.score1 != widget.score1 ||
        oldWidget.score2 != widget.score2 ||
        oldWidget.timestamp != widget.timestamp) {
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
      statusCode: widget.statusCode,
      period: widget.period,
      minute: widget.minute,
      extraTime: widget.extraTime,
      time: widget.time,
      date: widget.date,
      score1: widget.score1,
      score2: widget.score2,
      timestamp: widget.timestamp,
    );

    int minNum = 0;
    int secNum = _currentSecond;
    int? extraSecFromMinute;

    if (widget.minute != null &&
        widget.minute!.isNotEmpty &&
        widget.minute != 'null') {
      final clean = widget.minute!.replaceAll("'", '').trim();
      if (clean.contains('+')) {
        final parts = clean.split('+');
        minNum = int.tryParse(parts[0].trim()) ?? 0;
        final extraPart = parts.length > 1 ? parts[1].trim() : '';
        if (extraPart.contains(':')) {
          final t = extraPart.split(':');
          final m = int.tryParse(t[0].trim()) ?? 0;
          final s = int.tryParse(t[1].trim()) ?? 0;
          extraSecFromMinute = m * 60 + s;
        } else {
          final m = int.tryParse(extraPart) ?? 0;
          extraSecFromMinute = m * 60;
        }
      } else if (clean.contains(':')) {
        final parts = clean.split(':');
        minNum = int.tryParse(parts[0].trim()) ?? 0;
        if (parts.length > 1) {
          secNum = int.tryParse(parts[1].trim()) ?? 0;
        }
      } else {
        minNum = int.tryParse(clean) ?? 0;
      }
    }

    if (minNum == 0) {
      final est = MatchStatusHelper.estimateMatchMinutes(
        time: widget.time,
        status: widget.status,
        period: widget.period,
        timestamp: widget.timestamp,
      );
      minNum = est.minute;
      if (est.extraMinute > 0) {
        extraSecFromMinute ??= est.extraMinute * 60;
      }
    }

    final syncedClock = LiveClockSync.getLiveClock(widget.matchId);
    if (syncedClock != null) {
      if (syncedClock.minute >= minNum && minNum > 0) {
        minNum = syncedClock.minute;
        secNum = syncedClock.second;
      } else if (minNum == 0 && syncedClock.minute > 0) {
        minNum = syncedClock.minute;
        secNum = syncedClock.second;
      }
    }

    _currentMinute = minNum;
    _currentSecond = secNum;

    // Detect periods
    final p = (widget.period ?? '').toLowerCase();
    final s = (widget.status ?? '').toLowerCase();
    final is1stHalf =
        p.contains('1st') ||
        p.contains('first') ||
        s.contains('الأول') ||
        s.contains('الاول');
    final is2ndHalf =
        p.contains('2nd') || p.contains('second') || s.contains('الثاني');
    final is1stExtra =
        p.contains('1st_extra') ||
        s.contains('الإضافي الأول') ||
        s.contains('الاضافي الاول');
    final is2ndExtra =
        p.contains('2nd_extra') ||
        s.contains('الإضافي الثاني') ||
        s.contains('الاضافي الثاني');

    final isHt = _phase == MatchPhase.halfTime;
    final isPen = _phase == MatchPhase.penalties;
    final isFinished = _phase == MatchPhase.finished;

    // Stoppage time is ONLY active at >=45 in 1st half, >=90 in 2nd half, >=105 in 1st ET, >=120 in 2nd ET
    bool isStoppageEligible = false;
    int regularBaseMinute = 90;
    if (is1stHalf) {
      regularBaseMinute = 45;
      isStoppageEligible = minNum >= 45 || extraSecFromMinute != null;
    } else if (is2ndHalf) {
      regularBaseMinute = 90;
      isStoppageEligible = minNum >= 90 || extraSecFromMinute != null;
    } else if (is1stExtra) {
      regularBaseMinute = 105;
      isStoppageEligible = minNum >= 105 || extraSecFromMinute != null;
    } else if (is2ndExtra) {
      regularBaseMinute = 120;
      isStoppageEligible = minNum >= 120 || extraSecFromMinute != null;
    } else {
      if (minNum >= 90) {
        regularBaseMinute = 90;
        isStoppageEligible = true;
      } else if (minNum >= 45 && minNum < 60) {
        regularBaseMinute = 45;
        isStoppageEligible = true;
      }
    }

    _displayExtra = null;

    if (isHt || isPen || isFinished) {
      _elapsedExtraSeconds = 0;
      _totalExtraMinutes = 0;
      if (isFinished) {
        LiveClockSync.clearMatch(widget.matchId);
      }
    } else if (!isStoppageEligible) {
      _elapsedExtraSeconds = 0;
      _totalExtraMinutes = 0;
    } else {
      // Calculate elapsed extra time from minute, second, or existing running timer
      int computedElapsedExtraSec = 0;
      if (extraSecFromMinute != null) {
        computedElapsedExtraSec = extraSecFromMinute;
      } else if (minNum >= regularBaseMinute) {
        computedElapsedExtraSec = (minNum - regularBaseMinute) * 60 + secNum;
      }

      // Check if another screen (e.g. Homepage or MatchDetails) already has an active ticking clock for this match
      if (syncedClock != null && syncedClock.elapsedExtraSeconds > 0) {
        if (computedElapsedExtraSec == 0 ||
            syncedClock.elapsedExtraSeconds > computedElapsedExtraSec) {
          computedElapsedExtraSec = syncedClock.elapsedExtraSeconds;
        }
      }

      // If computed is 0 but we already had an active timer running in this widget, preserve it
      if (computedElapsedExtraSec == 0 && _elapsedExtraSeconds > 0) {
        computedElapsedExtraSec = _elapsedExtraSeconds;
      }

      // If still 0 and not synced, check estimate from kickoff time
      if (computedElapsedExtraSec == 0 &&
          (syncedClock == null || syncedClock.elapsedExtraSeconds == 0)) {
        final est = MatchStatusHelper.estimateMatchMinutes(
          time: widget.time,
          status: widget.status,
          period: widget.period,
          timestamp: widget.timestamp,
        );
        if (est.extraMinute > 0) {
          computedElapsedExtraSec = est.extraMinute * 60;
        }
      }

      int parsedTotalExtraMinutes = 0;
      int? explicitElapsedSec;

      if (widget.extraTime != null &&
          widget.extraTime!.isNotEmpty &&
          widget.extraTime != 'null') {
        final clean = widget.extraTime!.trim();
        if (clean != '+00:00' &&
            clean != '00:00' &&
            clean != '0' &&
            clean != '+0') {
          if (clean.contains('/')) {
            final parts = clean.split('/');
            final elapsedPart = parts.first.replaceAll('+', '').trim();
            final totalPart = parts.last.trim();
            parsedTotalExtraMinutes = int.tryParse(totalPart) ?? 0;
            if (elapsedPart.contains(':')) {
              final timeParts = elapsedPart.split(':');
              final m = int.tryParse(timeParts[0]) ?? 0;
              final s = int.tryParse(timeParts[1]) ?? 0;
              explicitElapsedSec = m * 60 + s;
            } else {
              final m = int.tryParse(elapsedPart) ?? 0;
              explicitElapsedSec = m * 60;
            }
          } else if (clean.contains(':')) {
            final cleanTime = clean.replaceAll('+', '').trim();
            final timeParts = cleanTime.split(':');
            final m = int.tryParse(timeParts[0]) ?? 0;
            final s = int.tryParse(timeParts[1]) ?? 0;
            explicitElapsedSec = m * 60 + s;
          } else {
            final numMatch = RegExp(r'(\d+)').firstMatch(clean);
            if (numMatch != null) {
              parsedTotalExtraMinutes = int.tryParse(numMatch.group(1)!) ?? 0;
            }
          }
        }
      }

      if (parsedTotalExtraMinutes == 0 &&
          syncedClock != null &&
          syncedClock.totalExtraMinutes > 0) {
        parsedTotalExtraMinutes = syncedClock.totalExtraMinutes;
      }

      _elapsedExtraSeconds = explicitElapsedSec ?? computedElapsedExtraSec;
      if (syncedClock != null &&
          syncedClock.elapsedExtraSeconds > _elapsedExtraSeconds) {
        _elapsedExtraSeconds = syncedClock.elapsedExtraSeconds;
      }
      _totalExtraMinutes = parsedTotalExtraMinutes > 0
          ? parsedTotalExtraMinutes
          : (_totalExtraMinutes > 0 ? _totalExtraMinutes : 0);

      final mm = (_elapsedExtraSeconds ~/ 60).toString().padLeft(2, '0');
      final ss = (_elapsedExtraSeconds % 60).toString().padLeft(2, '0');
      if (_totalExtraMinutes > 0) {
        _displayExtra = '+$mm:$ss / $_totalExtraMinutes';
      } else if (_elapsedExtraSeconds > 0) {
        _displayExtra = '+$mm:$ss';
      } else if (widget.extraTime != null &&
          widget.extraTime!.startsWith('+')) {
        _displayExtra = widget.extraTime;
      }

      // Record state in sync registry
      if (_elapsedExtraSeconds > 0 ||
          _totalExtraMinutes > 0 ||
          _currentMinute > 0) {
        LiveClockSync.recordClock(
          matchId: widget.matchId,
          minute: _currentMinute,
          second: _currentSecond,
          elapsedExtraSeconds: _elapsedExtraSeconds,
          totalExtraMinutes: _totalExtraMinutes,
        );
      }
    }

    _updateDisplayMinute();
  }

  void _updateDisplayMinute() {
    if (_phase == MatchPhase.halfTime) {
      _displayMinute = 'HT';
      _displayExtra = null;
    } else if (_phase == MatchPhase.penalties) {
      _displayMinute = 'PEN';
      _displayExtra = null;
    } else {
      final p = (widget.period ?? '').toLowerCase();
      final s = (widget.status ?? '').toLowerCase();
      final is1stHalf =
          p.contains('1st') ||
          p.contains('first') ||
          s.contains('الأول') ||
          s.contains('الاول');

      int m = _currentMinute;
      int sec = _currentSecond;
      if (_displayExtra != null) {
        if (is1stHalf && m >= 45) {
          m = 45;
          sec = 0; // When extra time starts, main time is strictly 45:00
        } else if (m >= 90) {
          m = 90;
          sec = 0; // When extra time starts, main time is strictly 90:00
        }
      }

      final mm = m.toString().padLeft(2, '0');
      final ss = (sec % 60).toString().padLeft(2, '0');
      _displayMinute = '$mm:$ss';
    }
  }

  void _startTimerIfNeeded() {
    _timer?.cancel();
    if (!_isInTest &&
        MatchStatusHelper.isInPlay(_phase) &&
        _currentMinute >= 0 &&
        _currentMinute < 130) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          if (_displayExtra != null) {
            // Cap stoppage time ticking to at most (totalExtraMinutes + 3) * 60 seconds
            // to prevent runaway counter if network drops whistle event
            final maxExtraSec = _totalExtraMinutes > 0
                ? (_totalExtraMinutes + 3) * 60
                : 600;
            if (_elapsedExtraSeconds < maxExtraSec) {
              _elapsedExtraSeconds++;
            }
            final mm = (_elapsedExtraSeconds ~/ 60).toString().padLeft(2, '0');
            final ss = (_elapsedExtraSeconds % 60).toString().padLeft(2, '0');
            if (_totalExtraMinutes > 0) {
              _displayExtra = '+$mm:$ss / $_totalExtraMinutes';
            } else {
              _displayExtra = '+$mm:$ss';
            }
          } else {
            _currentSecond++;
            if (_currentSecond >= 60) {
              _currentSecond = 0;
              _currentMinute++;
            }
          }
          LiveClockSync.recordClock(
            matchId: widget.matchId,
            minute: _currentMinute,
            second: _currentSecond,
            elapsedExtraSeconds: _elapsedExtraSeconds,
            totalExtraMinutes: _totalExtraMinutes,
          );
          _updateDisplayMinute();
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

    final clockWidget = RepaintBoundary(
      child: SizedBox(
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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.size * 0.08),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _displayMinute,
                  style: TextStyle(
                    color: effectiveTextColor,
                    fontSize: widget.size * 0.24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (_displayExtra != null && _displayExtra!.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          clockWidget,
          const SizedBox(height: 2),
          Text(
            _displayExtra!,
            style: TextStyle(
              color: const Color(0xFFFF4B4B),
              fontSize: (widget.size * 0.18).clamp(9.5, 11.5),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
            textDirection: TextDirection.ltr,
          ),
        ],
      );
    }

    return clockWidget;
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
    final trackPaint = Paint()
      ..color = arcColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    // 2. Active Progress Arc (starts from 12 o'clock, sweeping clockwise)
    const startAngle = -pi / 2;
    final sweepAngle = (progress * 2 * pi).clamp(0.01, 2 * pi);

    final arcPaint = Paint()
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
    final notchPaint = Paint()
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
    final spokePaint = Paint()
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
