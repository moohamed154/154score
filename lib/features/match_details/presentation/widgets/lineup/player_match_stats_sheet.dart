import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:score154/core/constants/app_colors.dart';
import 'package:score154/core/constants/app_dimensions.dart';
import 'package:score154/core/di/injection_container.dart';
import 'package:score154/core/utils/url_helper.dart';
import 'package:score154/features/match_details/domain/entities/match_details_entity.dart';
import 'package:score154/features/match_details/domain/entities/player_match_rating_entity.dart';
import 'package:score154/features/match_details/domain/repositories/match_details_repository.dart';

class PlayerMatchStatsSheet extends StatefulWidget {
  final LineupPlayerEntity player;
  final String matchId;
  final bool isArabic;
  final List<MatchEventEntity> playerEvents;

  const PlayerMatchStatsSheet({
    super.key,
    required this.player,
    required this.matchId,
    required this.isArabic,
    this.playerEvents = const [],
  });

  static Future<void> show({
    required BuildContext context,
    required LineupPlayerEntity player,
    required String matchId,
    required bool isArabic,
    List<MatchEventEntity> playerEvents = const [],
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => PlayerMatchStatsSheet(
        player: player,
        matchId: matchId,
        isArabic: isArabic,
        playerEvents: playerEvents,
      ),
    );
  }

  @override
  State<PlayerMatchStatsSheet> createState() => _PlayerMatchStatsSheetState();
}

class _PlayerMatchStatsSheetState extends State<PlayerMatchStatsSheet> {
  PlayerMatchRatingEntity? _ratingData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlayerRating();
  }

  Future<void> _fetchPlayerRating() async {
    final playerId = widget.player.playerId?.trim();
    if (playerId == null || playerId.isEmpty || playerId == '0') {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final repo = sl<MatchDetailsRepository>();
      final res = await repo.getPlayerMatchRating(
        widget.matchId,
        playerId,
        lang: widget.isArabic ? 'ar' : 'en',
      );
      if (mounted) {
        setState(() {
          _ratingData = res.dataOrNull;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = widget.isArabic;
    final p = widget.player;
    final r = _ratingData;

    final sheetBg = isDark ? const Color(0xFF0B131E) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF131D2E) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF1E2D44) : const Color(0xFFE2E8F0);
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final ratingString = r?.player.rating ?? p.rating;
    final playerName = r?.player.name.isNotEmpty == true ? r!.player.name : p.name;
    final positionTitle = r?.player.positionTitle ??
        p.detailedPosition ??
        p.position ??
        (p.isGoalkeeper ? (isArabic ? 'حارس المرمى' : 'Goalkeeper') : '');
    final playerPhoto = r?.player.photo ?? p.photo;
    final playerNumber = r?.player.number ?? p.number;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Drag Handle
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Main Scrollable Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row (Photo, Number, Name, Position, Rating)
                    _buildHeaderRow(
                      isDark: isDark,
                      isArabic: isArabic,
                      name: playerName,
                      positionTitle: positionTitle,
                      photo: playerPhoto,
                      number: playerNumber,
                      rating: ratingString,
                      primaryColor: primaryTextColor,
                      mutedColor: mutedTextColor,
                    ),
                    const SizedBox(height: 16),

                    if (_isLoading)
                      _buildLoadingSkeleton(isDark: isDark)
                    else if (r != null) ...[
                      // Goals & Assists Highlight Box
                      _buildGoalsAssistsBox(
                        isDark: isDark,
                        isArabic: isArabic,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        goals: r.highlights.goals > 0 ? r.highlights.goals : p.goals,
                        assists: r.highlights.assists > 0 ? r.highlights.assists : p.assists,
                      ),
                      const SizedBox(height: 18),

                      // Section: Shooting
                      if (_hasShootingStats(r)) ...[
                        _buildSectionHeader(
                          color: const Color(0xFFF43F5E),
                          icon: Icons.sports_soccer_rounded,
                          title: isArabic ? 'التسديدات' : 'Shooting',
                          isArabic: isArabic,
                        ),
                        const SizedBox(height: 8),
                        _buildShootingSection(
                          r: r,
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          primaryTextColor: primaryTextColor,
                          isArabic: isArabic,
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Section: Passing
                      if (_hasPassingStats(r)) ...[
                        _buildSectionHeader(
                          color: const Color(0xFF3B82F6),
                          icon: Icons.swap_horiz_rounded,
                          title: isArabic ? 'التمريرات' : 'Passing',
                          isArabic: isArabic,
                        ),
                        const SizedBox(height: 8),
                        _buildPassingSection(
                          r: r,
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          primaryTextColor: primaryTextColor,
                          mutedTextColor: mutedTextColor,
                          isArabic: isArabic,
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Section: Defending & Duels
                      if (_hasDefendingStats(r)) ...[
                        _buildSectionHeader(
                          color: const Color(0xFF10B981),
                          icon: Icons.shield_outlined,
                          title: isArabic ? 'الدفاع والالتحامات' : 'Defending & Duels',
                          isArabic: isArabic,
                        ),
                        const SizedBox(height: 8),
                        _buildDefendingSection(
                          r: r,
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          primaryTextColor: primaryTextColor,
                          mutedTextColor: mutedTextColor,
                          isArabic: isArabic,
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Section: Dribbles & Duels
                      if (_hasDribblesStats(r)) ...[
                        _buildSectionHeader(
                          color: const Color(0xFFF59E0B),
                          icon: Icons.directions_run_rounded,
                          title: isArabic ? 'المراوغات والالتحامات' : 'Dribbles & Duels',
                          isArabic: isArabic,
                        ),
                        const SizedBox(height: 8),
                        _buildDribblesSection(
                          r: r,
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          primaryTextColor: primaryTextColor,
                          isArabic: isArabic,
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Section: Discipline & Fouls
                      if (_hasDisciplineStats(r, p)) ...[
                        _buildSectionHeader(
                          color: const Color(0xFFFB7185),
                          icon: Icons.style_outlined,
                          title: isArabic ? 'الانضباط والأخطاء' : 'Discipline & Fouls',
                          isArabic: isArabic,
                        ),
                        const SizedBox(height: 8),
                        _buildDisciplineSection(
                          r: r,
                          p: p,
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          primaryTextColor: primaryTextColor,
                          isArabic: isArabic,
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Section: Other statistics
                      if (r.otherStatistics.isNotEmpty) ...[
                        _buildSectionHeader(
                          color: const Color(0xFF64748B),
                          icon: Icons.trending_up_rounded,
                          title: isArabic ? 'إحصائيات أخرى' : 'Other statistics',
                          isArabic: isArabic,
                        ),
                        const SizedBox(height: 8),
                        _buildOtherStatsSection(
                          stats: r.otherStatistics,
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          primaryTextColor: primaryTextColor,
                          isArabic: isArabic,
                        ),
                        const SizedBox(height: 18),
                      ],
                    ] else ...[
                      // Fallback when detailed stats are not available
                      _buildFallbackSummary(
                        isDark: isDark,
                        isArabic: isArabic,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        primaryTextColor: primaryTextColor,
                        mutedTextColor: mutedTextColor,
                        p: p,
                      ),
                      const SizedBox(height: 18),
                    ],
                  ],
                ),
              ),
            ),

            // Sticky Bottom Action Bar
            _buildStickyBottomButton(
              context: context,
              player: p,
              isArabic: isArabic,
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // Header Row
  // -------------------------------------------------------------
  Widget _buildHeaderRow({
    required bool isDark,
    required bool isArabic,
    required String name,
    required String positionTitle,
    required String? photo,
    required int? number,
    required String? rating,
    required Color primaryColor,
    required Color mutedColor,
  }) {
    final ratingNum = double.tryParse(rating ?? '');
    final ratingBg = ratingNum != null && ratingNum >= 7.0
        ? const Color(0xFF0F3932)
        : (ratingNum != null && ratingNum >= 6.0
            ? const Color(0xFF332A15)
            : const Color(0xFF232D3F));
    final ratingTextColor = ratingNum != null && ratingNum >= 7.0
        ? const Color(0xFF00E599)
        : (ratingNum != null && ratingNum >= 6.0
            ? const Color(0xFFFBBF24)
            : const Color(0xFF94A3B8));

    final normalizedPhoto = UrlHelper.normalizePlayerPhotoUrl(photo);

    return Row(
      children: [
        // Avatar Stack with Number overlay pill
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF1E2D44) : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
                color: isDark ? const Color(0xFF131D2E) : const Color(0xFFF1F5F9),
              ),
              child: ClipOval(
                child: (normalizedPhoto != null && UrlHelper.isValidImageUrl(normalizedPhoto))
                    ? CachedNetworkImage(
                        imageUrl: normalizedPhoto,
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                        memCacheWidth: 120,
                        memCacheHeight: 120,
                        placeholder: (_, __) => _buildJerseyNumber(number),
                        errorWidget: (_, __, ___) => _buildJerseyNumber(number),
                      )
                    : _buildJerseyNumber(number),
              ),
            ),
            if (number != null)
              Positioned(
                top: -2,
                left: isArabic ? null : -4,
                right: isArabic ? -4 : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF334155),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '$number',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 14),

        // Name & Position
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                positionTitle,
                style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: mutedColor,
                ),
              ),
            ],
          ),
        ),

        // Rating Pill
        if (rating != null && rating.isNotEmpty && rating != '-')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ratingBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ratingTextColor.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Text(
              rating,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: ratingTextColor,
              ),
            ),
          ),
      ],
    );
  }

  // -------------------------------------------------------------
  // Goals & Assists Box
  // -------------------------------------------------------------
  Widget _buildGoalsAssistsBox({
    required bool isDark,
    required bool isArabic,
    required Color cardBg,
    required Color cardBorder,
    required int goals,
    required int assists,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Row(
        children: [
          // Goals
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.sports_soccer_rounded,
                  color: Color(0xFF10B981),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  '$goals',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isArabic ? 'أهداف' : 'Goals',
                  style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 32,
            width: 1,
            color: cardBorder,
          ),
          // Assists
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.directions_run_rounded,
                  color: Color(0xFF94A3B8),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  '$assists',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isArabic ? 'صناعة' : 'Assists',
                  style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Section Header
  // -------------------------------------------------------------
  Widget _buildSectionHeader({
    required Color color,
    required IconData icon,
    required String title,
    required bool isArabic,
  }) {
    return Row(
      children: [
        Container(
          width: 3.5,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // Section: Shooting
  // -------------------------------------------------------------
  Widget _buildShootingSection({
    required PlayerMatchRatingEntity r,
    required Color cardBg,
    required Color cardBorder,
    required Color primaryTextColor,
    required bool isArabic,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: isArabic ? 'فرص محققة' : 'Big chances',
                value: '${r.shooting.bigChances}',
                cardBg: cardBg,
                cardBorder: cardBorder,
                primaryTextColor: primaryTextColor,
                isArabic: isArabic,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                title: isArabic ? 'على المرمى' : 'On target',
                value: '${r.shooting.onTarget}',
                valueColor: const Color(0xFF10B981),
                cardBg: cardBg,
                cardBorder: cardBorder,
                primaryTextColor: primaryTextColor,
                isArabic: isArabic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: isArabic ? 'خارج المرمى' : 'Off target',
                value: '${r.shooting.offTarget}',
                cardBg: cardBg,
                cardBorder: cardBorder,
                primaryTextColor: primaryTextColor,
                isArabic: isArabic,
              ),
            ),
            if (r.shooting.woodwork > 0) ...[
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  title: isArabic ? 'في القائم' : 'Woodwork',
                  value: '${r.shooting.woodwork}',
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  primaryTextColor: primaryTextColor,
                  isArabic: isArabic,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // Section: Passing
  // -------------------------------------------------------------
  Widget _buildPassingSection({
    required PlayerMatchRatingEntity r,
    required Color cardBg,
    required Color cardBorder,
    required Color primaryTextColor,
    required Color mutedTextColor,
    required bool isArabic,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Column(
        children: [
          // Pass Accuracy
          _buildProgressBarRow(
            title: isArabic ? 'دقة التمريرات' : 'Pass accuracy',
            fraction: '${r.passing.accuracy.success}/${r.passing.accuracy.total}',
            percent: r.passing.accuracy.percent,
            barColor: const Color(0xFF2563EB),
            primaryTextColor: primaryTextColor,
            mutedTextColor: mutedTextColor,
            isArabic: isArabic,
          ),
          const SizedBox(height: 14),

          // Accurate Crosses
          _buildProgressBarRow(
            title: isArabic ? 'عرضيات دقيقة' : 'Accurate crosses',
            fraction: '${r.passing.crosses.success}/${r.passing.crosses.total}',
            percent: r.passing.crosses.percent,
            barColor: const Color(0xFF9333EA),
            primaryTextColor: primaryTextColor,
            mutedTextColor: mutedTextColor,
            isArabic: isArabic,
          ),
          const SizedBox(height: 14),

          // Long balls
          _buildProgressBarRow(
            title: isArabic ? 'كرات طويلة' : 'Long balls',
            fraction: '${r.passing.longBalls.success}/${r.passing.longBalls.total}',
            percent: r.passing.longBalls.percent,
            barColor: const Color(0xFF14B8A6),
            primaryTextColor: primaryTextColor,
            mutedTextColor: mutedTextColor,
            isArabic: isArabic,
          ),
          const SizedBox(height: 14),

          // Bottom chips (Key Passes, Passes in Final Third)
          Row(
            children: [
              Expanded(
                child: _buildInnerChip(
                  title: isArabic ? 'تمريرات مفتاحية' : 'Key Passes',
                  value: '${r.passing.keyPasses}',
                  isArabic: isArabic,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInnerChip(
                  title: isArabic ? 'في الثلث الأخير' : 'Passes In Final Third',
                  value: '${r.passing.finalThird}',
                  isArabic: isArabic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Section: Defending & Duels
  // -------------------------------------------------------------
  Widget _buildDefendingSection({
    required PlayerMatchRatingEntity r,
    required Color cardBg,
    required Color cardBorder,
    required Color primaryTextColor,
    required Color mutedTextColor,
    required bool isArabic,
  }) {
    final duels = r.dribblesDuels.duels;
    final totalDuels = duels.total;
    final wonDuels = duels.won;
    final lostDuels = duels.lost;
    final wonRatio = totalDuels > 0 ? (wonDuels / totalDuels).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        // Segmented Duels Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cardBorder, width: 1),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isArabic ? '$wonDuels فوز' : '$wonDuels won',
                    style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  Text(
                    isArabic ? 'الالتحامات ($totalDuels)' : 'Duels ($totalDuels)',
                    style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: mutedTextColor,
                    ),
                  ),
                  Text(
                    isArabic ? 'خسارة $lostDuels' : 'lost $lostDuels',
                    style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF43F5E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Segmented bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 6,
                  width: double.infinity,
                  color: const Color(0xFFF43F5E),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: wonRatio,
                    child: Container(color: const Color(0xFF10B981)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Tackles & Interceptions
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: isArabic ? 'التدخلات' : 'Tackles',
                value: r.tacklesTotal > 0
                    ? '${r.tacklesWon}/${r.tacklesTotal}'
                    : '${r.tacklesWon}',
                cardBg: cardBg,
                cardBorder: cardBorder,
                primaryTextColor: primaryTextColor,
                isArabic: isArabic,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricTile(
                title: isArabic ? 'اعتراضات' : 'Interceptions',
                value: '${r.interceptions}',
                cardBg: cardBg,
                cardBorder: cardBorder,
                primaryTextColor: primaryTextColor,
                isArabic: isArabic,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // Section: Dribbles & Duels
  // -------------------------------------------------------------
  Widget _buildDribblesSection({
    required PlayerMatchRatingEntity r,
    required Color cardBg,
    required Color cardBorder,
    required Color primaryTextColor,
    required bool isArabic,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: isArabic ? 'فقدان الكرة' : 'Possession Lost',
            value: '${r.possessionLost}',
            cardBg: cardBg,
            cardBorder: cardBorder,
            primaryTextColor: primaryTextColor,
            isArabic: isArabic,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            title: isArabic ? 'افتكاك منه' : 'Dispossessed',
            value: '${r.dispossessed}',
            cardBg: cardBg,
            cardBorder: cardBorder,
            primaryTextColor: primaryTextColor,
            isArabic: isArabic,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // Section: Discipline & Fouls
  // -------------------------------------------------------------
  Widget _buildDisciplineSection({
    required PlayerMatchRatingEntity r,
    required LineupPlayerEntity p,
    required Color cardBg,
    required Color cardBorder,
    required Color primaryTextColor,
    required bool isArabic,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: isArabic ? 'أخطاء مُكتسبة' : 'Fouls Drawn',
            value: '${r.foulsDrawn}',
            cardBg: cardBg,
            cardBorder: cardBorder,
            primaryTextColor: primaryTextColor,
            isArabic: isArabic,
          ),
        ),
        if (r.foulsCommitted > 0) ...[
          const SizedBox(width: 10),
          Expanded(
            child: _buildMetricTile(
              title: isArabic ? 'أخطاء مرتكبة' : 'Fouls Committed',
              value: '${r.foulsCommitted}',
              cardBg: cardBg,
              cardBorder: cardBorder,
              primaryTextColor: primaryTextColor,
              isArabic: isArabic,
            ),
          ),
        ] else if (p.yellowCards > 0 || p.redCards > 0) ...[
          const SizedBox(width: 10),
          Expanded(
            child: _buildMetricTile(
              title: isArabic ? 'البطاقات' : 'Cards',
              value: p.redCards > 0
                  ? '🟥 ${p.redCards}'
                  : '🟨 ${p.yellowCards}',
              cardBg: cardBg,
              cardBorder: cardBorder,
              primaryTextColor: primaryTextColor,
              isArabic: isArabic,
            ),
          ),
        ],
      ],
    );
  }

  // -------------------------------------------------------------
  // Section: Other statistics
  // -------------------------------------------------------------
  Widget _buildOtherStatsSection({
    required List<PlayerRatingStatItem> stats,
    required Color cardBg,
    required Color cardBorder,
    required Color primaryTextColor,
    required bool isArabic,
  }) {
    return Column(
      children: stats.map((item) {
        final val = item.value;
        final isPercent = item.code.toLowerCase().contains('percentage') ||
            item.title.contains('نسبة') ||
            item.title.toLowerCase().contains('percentage');
        final displayVal = isPercent ? '$val%' : '$val';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isArabic ? Colors.white70 : const Color(0xFFCBD5E1),
                  ),
                ),
              ),
              Text(
                displayVal,
                style: GoogleFonts.outfit(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // -------------------------------------------------------------
  // Fallback summary (when no Opta/YSScores rating data is available)
  // -------------------------------------------------------------
  Widget _buildFallbackSummary({
    required bool isDark,
    required bool isArabic,
    required Color cardBg,
    required Color cardBorder,
    required Color primaryTextColor,
    required Color mutedTextColor,
    required LineupPlayerEntity p,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAttrCol(
                title: isArabic ? 'الحالة' : 'Status',
                value: p.isStarter
                    ? (isArabic ? 'أساسي' : 'Starter')
                    : (isArabic ? 'بديل' : 'Substitute'),
                isArabic: isArabic,
                primaryColor: primaryTextColor,
                mutedColor: mutedTextColor,
              ),
              _buildAttrCol(
                title: isArabic ? 'القائد' : 'Captain',
                value: p.isCaptain ? (isArabic ? 'نعم' : 'Yes') : (isArabic ? 'لا' : 'No'),
                isArabic: isArabic,
                primaryColor: primaryTextColor,
                mutedColor: mutedTextColor,
              ),
              if (p.isManOfMatch)
                _buildAttrCol(
                  title: isArabic ? 'الأفضل' : 'MOTM',
                  value: isArabic ? '⭐ نعم' : '⭐ Yes',
                  isArabic: isArabic,
                  primaryColor: const Color(0xFFF59E0B),
                  mutedColor: mutedTextColor,
                ),
            ],
          ),
          if (p.goals > 0 || p.assists > 0 || p.yellowCards > 0 || p.redCards > 0) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (p.goals > 0)
                  _buildTag(
                    icon: Icons.sports_soccer_rounded,
                    label: '${p.goals} ${isArabic ? "هدف" : "Goals"}',
                    color: const Color(0xFF10B981),
                    isArabic: isArabic,
                  ),
                if (p.assists > 0)
                  _buildTag(
                    icon: Icons.directions_run_rounded,
                    label: '${p.assists} ${isArabic ? "صناعة" : "Assists"}',
                    color: const Color(0xFF3B82F6),
                    isArabic: isArabic,
                  ),
                if (p.yellowCards > 0)
                  _buildTag(
                    icon: Icons.style_rounded,
                    label: '${p.yellowCards} ${isArabic ? "بطاقة صفراء" : "Yellow"}',
                    color: const Color(0xFFFBBF24),
                    isArabic: isArabic,
                  ),
                if (p.redCards > 0)
                  _buildTag(
                    icon: Icons.style_rounded,
                    label: '${p.redCards} ${isArabic ? "بطاقة حمراء" : "Red"}',
                    color: const Color(0xFFEF4444),
                    isArabic: isArabic,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Sticky Bottom Action Button
  // -------------------------------------------------------------
  Widget _buildStickyBottomButton({
    required BuildContext context,
    required LineupPlayerEntity player,
    required bool isArabic,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0B131E)
            : const Color(0xFFF8FAFC),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            final cleanName = player.name.trim();
            final pId = player.playerId ?? '0';
            final slug = Uri.encodeComponent(
              cleanName.replaceAll(RegExp(r'\s+'), '-'),
            );
            context.push('/player/$pId/$slug');
          },
          icon: const Icon(
            Icons.visibility_outlined,
            size: 20,
            color: Color(0xFF0F172A),
          ),
          label: Text(
            isArabic ? 'عرض الملف الشخصي للاعب' : 'View player profile',
            style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00E599),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // Helpers & Reusable Sub-widgets
  // -------------------------------------------------------------
  Widget _buildMetricTile({
    required String title,
    required String value,
    Color? valueColor,
    required Color cardBg,
    required Color cardBorder,
    required Color primaryTextColor,
    required bool isArabic,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: valueColor ?? primaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBarRow({
    required String title,
    required String fraction,
    required int percent,
    required Color barColor,
    required Color primaryTextColor,
    required Color mutedTextColor,
    required bool isArabic,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: primaryTextColor,
              ),
            ),
            Row(
              children: [
                Text(
                  fraction,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: mutedTextColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$percent%',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 5,
            width: double.infinity,
            color: const Color(0xFF1E293B),
            child: FractionallySizedBox(
              alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
              widthFactor: (percent / 100.0).clamp(0.0, 1.0),
              child: Container(color: barColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInnerChip({
    required String title,
    required String value,
    required bool isArabic,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E293B), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              title,
              style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF94A3B8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttrCol({
    required String title,
    required String value,
    required bool isArabic,
    required Color primaryColor,
    required Color mutedColor,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: mutedColor,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTag({
    required IconData icon,
    required String label,
    required Color color,
    required bool isArabic,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJerseyNumber(int? number) {
    return Container(
      color: const Color(0xFF131D2E),
      alignment: Alignment.center,
      child: number != null
          ? Text(
              '$number',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF00E599),
              ),
            )
          : const Icon(Icons.person, size: 24, color: Colors.white70),
    );
  }

  Widget _buildLoadingSkeleton({required bool isDark}) {
    return Column(
      children: List.generate(
        4,
        (i) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 60,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131D2E) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  bool _hasShootingStats(PlayerMatchRatingEntity r) =>
      r.shooting.bigChances > 0 || r.shooting.onTarget > 0 || r.shooting.offTarget > 0;

  bool _hasPassingStats(PlayerMatchRatingEntity r) =>
      r.passing.accuracy.total > 0 ||
      r.passing.crosses.total > 0 ||
      r.passing.longBalls.total > 0 ||
      r.passing.keyPasses > 0 ||
      r.passing.finalThird > 0;

  bool _hasDefendingStats(PlayerMatchRatingEntity r) =>
      r.dribblesDuels.duels.total > 0 || r.tacklesWon > 0 || r.interceptions > 0;

  bool _hasDribblesStats(PlayerMatchRatingEntity r) =>
      r.possessionLost > 0 || r.dispossessed > 0;

  bool _hasDisciplineStats(PlayerMatchRatingEntity r, LineupPlayerEntity p) =>
      r.foulsDrawn > 0 || r.foulsCommitted > 0 || p.yellowCards > 0 || p.redCards > 0;
}
