import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../localization/app_localizations.dart';
import '../utils/match_status_helper.dart';

class LiveMatchClock extends StatefulWidget {
  final String? status;
  final String? minute;
  final String? extraTime;
  final String? time;
  final String? period;
  final bool showLiveDot;
  final TextStyle? textStyle;

  static bool enablePulseAnimation = true;

  const LiveMatchClock({
    super.key,
    this.status,
    this.minute,
    this.extraTime,
    this.time,
    this.period,
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
        oldWidget.extraTime != widget.extraTime ||
        oldWidget.time != widget.time ||
        oldWidget.period != widget.period) {
      _syncClock();
      _startTimerIfNeeded();
    }
  }

  void _syncClock() {
    final phase = MatchStatusHelper.parseStatus(
      widget.status,
      minute: widget.minute,
      extraTime: widget.extraTime,
      time: widget.time,
    );

    int? minuteNum;
    if (widget.minute != null &&
        widget.minute!.isNotEmpty &&
        widget.minute != 'null') {
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
        minuteNum = base;
      }
    } else if (MatchStatusHelper.isLive(phase) &&
        widget.time != null &&
        widget.time!.isNotEmpty &&
        widget.time != '-') {
      final estimatedNum = MatchStatusHelper.estimateMinuteNumber(
        time: widget.time,
        status: widget.status,
        period: widget.period,
      );
      if (estimatedNum != null) {
        _currentMinute = estimatedNum;
        minuteNum = estimatedNum;
      }
    }

    final formattedExtra = MatchStatusHelper.formatExtraTime(
      widget.extraTime,
      minute: minuteNum ?? _currentMinute,
    );

    if (MatchStatusHelper.isLive(phase)) {
      if (_currentMinute > 0) {
        if (formattedExtra != null) {
          _displayString = "$_currentMinute' $formattedExtra";
        } else {
          _displayString = "$_currentMinute'";
        }
      } else if (formattedExtra != null) {
        _displayString = formattedExtra;
      } else {
        _displayString = '';
      }
    } else {
      _displayString = '';
    }
  }

  void _startTimerIfNeeded() {
    _timer?.cancel();
    final phase = MatchStatusHelper.parseStatus(
      widget.status,
      minute: widget.minute,
      extraTime: widget.extraTime,
      time: widget.time,
    );

    if (!_isInTest &&
        phase == MatchPhase.live &&
        _currentMinute > 0 &&
        _currentMinute < 125) {
      _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
        if (mounted) {
          setState(() {
            _currentMinute++;
            final formattedExtra = MatchStatusHelper.formatExtraTime(
              widget.extraTime,
              minute: _currentMinute,
            );
            if (formattedExtra != null) {
              _displayString = "$_currentMinute' $formattedExtra";
            } else {
              _displayString = "$_currentMinute'";
            }
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
      extraTime: widget.extraTime,
      time: widget.time,
    );

    final isLive = MatchStatusHelper.isLive(phase);

    final label = _displayString.isNotEmpty
        ? _displayString
        : MatchStatusHelper.getDisplayLabel(
            phase,
            widget.status,
            minute: widget.minute,
            extraTime: widget.extraTime,
            time: widget.time,
            period: widget.period,
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
