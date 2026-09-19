import 'dart:async';
import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../home/presentation/cubit/home_cubit.dart';
import '../../../matches/presentation/bloc/matches_bloc.dart';
import '../../../matches/presentation/bloc/matches_event.dart';
import '../../../matches/presentation/bloc/matches_state.dart';

/// A custom, high-performance animated splash screen for 154Score.
/// Built with zero external dependencies, leveraging pure Flutter animations
/// and RepaintBoundary-isolated canvas painting for 60/120 FPS rendering.
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Staged animation curves
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _logoScaleAnimation;
  late final Animation<double> _logoFadeAnimation;
  late final Animation<double> _titleFadeAnimation;
  late final Animation<Offset> _titleSlideAnimation;
  late final Animation<double> _subtitleFadeAnimation;
  late final Animation<double> _progressAnimation;
  late final Animation<double> _exitFadeAnimation;

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // 1. Ambient Sonar/Radar Pulse Wave (0% - 65%)
    _pulseAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
    );

    // 2. Logo Icon Scale & Elastic Bounce (10% - 60%)
    _logoScaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 0.60, curve: Curves.elasticOut),
    );

    // 3. Logo Fade In (5% - 40%)
    _logoFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.05, 0.40, curve: Curves.easeIn),
    );

    // 4. App Title Reveal (35% - 70%)
    _titleFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.70, curve: Curves.easeOut),
    );
    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.70, curve: Curves.easeOutCubic),
      ),
    );

    // 5. Subtitle Tagline Reveal (50% - 85%)
    _subtitleFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.50, 0.85, curve: Curves.easeOut),
    );

    // 6. Smooth Shimmer Progress Bar (30% - 95%)
    _progressAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.30, 0.95, curve: Curves.easeInOutCubic),
    );

    // 7. Graceful Exit Fade (92% - 100%)
    _exitFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.92, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNext();
      }
    });

    _controller.forward();
    _startBackgroundPreload();
  }

  /// Asynchronously preloads home screen feeds and live matches
  /// in the background without blocking the splash screen animation.
  void _startBackgroundPreload() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Stagger by 120ms to allow smooth initial GPU rasterization of entrance animation
      Future.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;

        // 1. Preload Home Cubit (videos, transfers, cached feeds)
        try {
          final homeCubit = context.read<HomeCubit>();
          if (homeCubit.state.status == HomeStatus.initial) {
            unawaited(homeCubit.loadHomeData());
          }
        } catch (_) {}

        // 2. Preload Matches Bloc (today's fixtures, live scores, leagues)
        try {
          final matchesBloc = context.read<MatchesBloc>();
          if (matchesBloc.state.status == MatchesStatus.initial) {
            matchesBloc.add(
              LoadMatchesEvent(date: matchesBloc.state.selectedDate),
            );
          }
        } catch (_) {}
      });
    });
  }

  void _navigateToNext() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    try {
      if (GoRouter.maybeOf(context) != null) {
        context.go('/');
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _navigateToNext, // Tap anywhere to skip splash
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _exitFadeAnimation.value,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Isolated Custom Canvas for Pitch Geometry & Radar Glow
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: _StadiumAmbiencePainter(
                        pulseProgress: _pulseAnimation.value,
                        brandColor: AppColors.primary,
                      ),
                    ),
                  ),

                  // 2. Central Content
                  SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 3),

                        // Logo Badge & Pulsing Ring
                        _buildAnimatedLogo(),

                        const SizedBox(height: 28),

                        // Animated Brand Title ("154SCORE")
                        _buildAnimatedTitle(isArabic),

                        const SizedBox(height: 12),

                        // Tagline Subtitle
                        _buildAnimatedSubtitle(isArabic),

                        const Spacer(flex: 2),

                        // Sleek Capsule Progress Bar
                        _buildProgressBar(),

                        const SizedBox(height: 36),

                        // Bottom Footer Details
                        _buildFooter(),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return FadeTransition(
      opacity: _logoFadeAnimation,
      child: ScaleTransition(
        scale: _logoScaleAnimation,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer Pulsing Glow Aura
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(
                      alpha: 0.28 * (1.0 - _pulseAnimation.value),
                    ),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),

            // Secondary Ring
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
            ),

            // Central Premium Emblem
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E2836),
                    Color(0xFF0D1117),
                  ],
                ),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.8),
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 24,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.sports_soccer_rounded,
                  size: 46,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedTitle(bool isArabic) {
    final titleFont = GoogleFonts.cairo(
      textStyle: const TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.0,
        height: 1.1,
      ),
    );

    return FadeTransition(
      opacity: _titleFadeAnimation,
      child: SlideTransition(
        position: _titleSlideAnimation,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '154',
              style: titleFont.copyWith(
                color: AppColors.primary,
                shadows: [
                  Shadow(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    blurRadius: 16,
                  ),
                ],
              ),
            ),
            Text(
              'SCORE',
              style: titleFont.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedSubtitle(bool isArabic) {
    final tagline = isArabic
        ? 'نتائج مباشرة • تغطية حية لحظة بلحظة'
        : 'LIVE MATCHES • SCORES & STATS';

    return FadeTransition(
      opacity: _subtitleFadeAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.darkSurface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.darkBorder.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Text(
          tagline,
          style: GoogleFonts.cairo(
            textStyle: TextStyle(
              fontSize: isArabic ? 13 : 11,
              fontWeight: FontWeight.w600,
              color: AppColors.darkTextSecondary,
              letterSpacing: isArabic ? 0.3 : 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    const barWidth = 180.0;
    const barHeight = 4.0;
    final progress = _progressAnimation.value.clamp(0.0, 1.0);

    return FadeTransition(
      opacity: _subtitleFadeAnimation,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: barWidth,
            height: barHeight,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(barHeight / 2),
            ),
            alignment: Alignment.centerLeft,
            child: Container(
              width: barWidth * progress,
              height: barHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(barHeight / 2),
                gradient: const LinearGradient(
                  colors: [
                    AppColors.primaryDark,
                    AppColors.primary,
                    AppColors.primaryLight,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.6),
                    blurRadius: 8,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return FadeTransition(
      opacity: _subtitleFadeAnimation,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '154SCORE v1.0.0',
            style: GoogleFonts.cairo(
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.darkTextMuted,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter rendering ambient stadium pitch geometry and expanding sonar wave
class _StadiumAmbiencePainter extends CustomPainter {
  final double pulseProgress;
  final Color brandColor;

  _StadiumAmbiencePainter({
    required this.pulseProgress,
    required this.brandColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);

    // 1. Ambient Central Radial Stadium Glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          brandColor.withValues(alpha: 0.12),
          brandColor.withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.7));

    canvas.drawCircle(center, size.width * 0.7, glowPaint);

    // 2. Football Center Pitch Lines (Subtle Tactical Geometry)
    final pitchLinePaint = Paint()
      ..color = brandColor.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Pitch center circle
    canvas.drawCircle(center, 90, pitchLinePaint);

    // Pitch halfway line segment
    final halfLineY = center.dy;
    canvas.drawLine(
      Offset(size.width * 0.15, halfLineY),
      Offset(size.width * 0.85, halfLineY),
      pitchLinePaint,
    );

    // Pitch center spot
    final spotPaint = Paint()
      ..color = brandColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3.0, spotPaint);

    // 3. Expanding Sonar/Radar Ring Wave
    if (pulseProgress > 0.0) {
      final waveRadius = 70.0 + (pulseProgress * 140.0);
      final waveOpacity = (1.0 - pulseProgress) * 0.35;

      final wavePaint = Paint()
        ..color = brandColor.withValues(alpha: math.max(0.0, waveOpacity))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(center, waveRadius, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StadiumAmbiencePainter oldDelegate) {
    return oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.brandColor != brandColor;
  }
}
