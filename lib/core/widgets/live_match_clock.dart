import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../localization/app_localizations.dart';
import '../utils/match_status_helper.dart';

class LiveMatchClock extends StatefulWidget {
  final String? status;
  final String? minute;
  final String? time;
  final bool showLiveDot;
  final TextStyle? textStyle;

  static bool enablePulseAnimation = true;

  const LiveMatchClock({
    super.key,
    this.status,
    this.minute,
    this.time,
    this.showLiveDot = true,
    this.textStyle,
  });

  @override
  State<LiveMatchClock> createState() => _LiveMatchClockState();
}

class _LiveMatchClockState extends State<LiveMatchClock>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _currentMinute = 0;
  String _displayString = '';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool get _isInTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    if (LiveMatchClock.enablePulseAnimation && !_isInTest) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.value = 1.0;
    }

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _syncClock();
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant LiveMatchClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status ||
        oldWidget.minute != widget.minute ||
        oldWidget.time != widget.time) {
      _syncClock();
      _startTimerIfNeeded();
    }
  }

  void _syncClock() {
    final phase = MatchStatusHelper.parseStatus(
      widget.status,
      minute: widget.minute,
      time: widget.time,
    );

    if (widget.minute != null && widget.minute!.isNotEmpty) {
      final clean = widget.minute!.replaceAll("'", '').trim();
      if (clean.contains('+')) {
        _displayString = "$clean'";
        final base = int.tryParse(clean.split('+')[0]);
        if (base != null) _currentMinute = base;
        return;
      }
      final base = int.tryParse(clean);
      if (base != null) {
        _currentMinute = base;
      }
    }

    if (phase == MatchPhase.live && _currentMinute > 0) {
      _displayString = "$_currentMinute'";
    } else {
      _displayString = '';
    }
  }

  void _startTimerIfNeeded() {
    _timer?.cancel();
    final phase = MatchStatusHelper.parseStatus(
      widget.status,
      minute: widget.minute,
      time: widget.time,
    );

    if (!_isInTest &&
        phase == MatchPhase.live &&
        _currentMinute > 0 &&
        _currentMinute < 120) {
      _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
        if (mounted) {
          setState(() {
            _currentMinute++;
            _displayString = "$_currentMinute'";
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    final phase = MatchStatusHelper.parseStatus(
      widget.status,
      minute: widget.minute,
      time: widget.time,
    );

    final isLive = MatchStatusHelper.isLive(phase);

    final label = _displayString.isNotEmpty
        ? _displayString
        : MatchStatusHelper.getDisplayLabel(
            phase,
            widget.status,
            minute: widget.minute,
            time: widget.time,
            isArabic: isArabic,
          );

    final defaultStyle =
        AppTypography.getBodySmall(isDark: isDark, isArabic: isArabic).copyWith(
          fontWeight: FontWeight.w700,
          color: isLive
              ? AppColors.liveRed
              : (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary),
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isLive && widget.showLiveDot) ...[
          FadeTransition(
            opacity: _pulseAnimation,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.liveRed,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: widget.textStyle ?? defaultStyle,
          textDirection: TextDirection.ltr,
        ),
      ],
    );
  }
}
