import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:score154/core/constants/app_colors.dart';
import 'package:score154/core/constants/app_dimensions.dart';
import 'package:score154/core/widgets/app_brand_logo.dart';
import 'package:score154/features/match_details/domain/entities/match_details_entity.dart';

import 'pitch_painter.dart';
import 'pitch_player_node.dart';

/// Interactive tactical pitch board displaying starting XI for a selected team
/// with a dedicated segmented toggle to seamlessly switch between Home & Away teams.
class MatchPitchWidget extends StatefulWidget {
  final TeamLineupEntity home;
  final TeamLineupEntity away;
  final int? selectedTeamIndex;
  final ValueChanged<int>? onTeamChanged;

  final bool isConfirmed;

  const MatchPitchWidget({
    super.key,
    required this.home,
    required this.away,
    this.selectedTeamIndex,
    this.onTeamChanged,
    this.isConfirmed = true,
  });

  @override
  State<MatchPitchWidget> createState() => _MatchPitchWidgetState();
}

class _MatchPitchWidgetState extends State<MatchPitchWidget> {
  int _internalTeamIndex = 0;

  int get _currentIndex => widget.selectedTeamIndex ?? _internalTeamIndex;

  void _onSelectTeam(int index) {
    if (widget.onTeamChanged != null) {
      widget.onTeamChanged!(index);
    } else {
      setState(() => _internalTeamIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Directionality.of(context) == TextDirection.rtl;

    final currentTeam = _currentIndex == 0 ? widget.home : widget.away;
    final isHome = _currentIndex == 0;
    final ringColor = isHome
        ? const Color(0xFF10B981)
        : const Color(0xFF38BDF8);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Team Segmented Toggle Switcher (Home vs Away)
            _buildTeamToggleBar(isDark: isDark, isArabic: isArabic),

            const SizedBox(height: 10),

            // 2. Interactive Football Pitch Turf
            GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity != null) {
                  if (details.primaryVelocity! < -200) {
                    // Swiped left
                    _onSelectTeam(isArabic ? 0 : 1);
                  } else if (details.primaryVelocity! > 200) {
                    // Swiped right
                    _onSelectTeam(isArabic ? 1 : 0);
                  }
                }
              },
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusLg - 1,
                  ),
                  child: AspectRatio(
                    aspectRatio: 1 / 1.40,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Pitch turf & markings
                        RepaintBoundary(
                          child: CustomPaint(
                            painter: PitchPainter(isDark: isDark),
                          ),
                        ),

                        // Pitch Brand Logo Watermark (bottom-left corner, blended on grass)
                        Positioned(
                          left: 28,
                          bottom: 26,
                          child: IgnorePointer(
                            child: AppBrandLogo(
                              size: 34,
                              isDark: isDark,
                              withBackground: false,
                              color: Colors.white,
                              opacity: 0.40,
                            ),
                          ),
                        ),

                        // Active Team Tactical Formation (Animated on toggle)
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                          child: KeyedSubtree(
                            key: ValueKey<int>(_currentIndex),
                            child: _buildSingleTeamPitch(
                              team: currentTeam,
                              otherTeam: isHome ? widget.away : widget.home,
                              isHome: isHome,
                              isDark: isDark,
                              isArabic: isArabic,
                            ),
                          ),
                        ),

                        // Floating Header Badge (Team name & formation)
                        Positioned(
                          top: 10,
                          left: 12,
                          right: 12,
                          child: _buildFloatingHeader(
                            team: currentTeam,
                            isHome: isHome,
                            ringColor: ringColor,
                            isArabic: isArabic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Segmented team toggle tab bar above the pitch board.
  Widget _buildTeamToggleBar({required bool isDark, required bool isArabic}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkCardElevated
              : AppColors.lightCardElevated,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            // Home Team Tab
            Expanded(
              child: _buildTeamToggleItem(
                team: widget.home,
                isSelected: _currentIndex == 0,
                isHome: true,
                accentColor: const Color(0xFF10B981),
                isDark: isDark,
                isArabic: isArabic,
                onTap: () => _onSelectTeam(0),
              ),
            ),
            const SizedBox(width: 4),
            // Away Team Tab
            Expanded(
              child: _buildTeamToggleItem(
                team: widget.away,
                isSelected: _currentIndex == 1,
                isHome: false,
                accentColor: const Color(0xFF38BDF8),
                isDark: isDark,
                isArabic: isArabic,
                onTap: () => _onSelectTeam(1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamToggleItem({
    required TeamLineupEntity team,
    required bool isSelected,
    required bool isHome,
    required Color accentColor,
    required bool isDark,
    required bool isArabic,
    required VoidCallback onTap,
  }) {
    final displayName = team.displayName.isNotEmpty
        ? team.displayName
        : (team.teamName ??
              (isHome
                  ? (isArabic ? 'صاحب الأرض' : 'Home')
                  : (isArabic ? 'الضيف' : 'Away')));

    final hasLineup = team.startingXi.isNotEmpty;
    const activeBorderColor = Color(
      0xFF00B4D8,
    ); // Cyan active border from Yalla Shoot screenshot
    final activeStatusColor = widget.isConfirmed
        ? const Color(0xFF10B981) // Emerald (Confirmed)
        : const Color(0xFFF59E0B); // Amber (Probable)
    final dotColor = hasLineup
        ? (isSelected ? activeStatusColor : Colors.grey.shade600)
        : (isSelected
              ? const Color(0xFFF59E0B).withValues(alpha: 0.8)
              : Colors.grey.shade600);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF0E253A) : Colors.white)
              : (isDark
                    ? const Color(0xFF141D2A)
                    : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm + 2),
          border: isSelected
              ? Border.all(color: activeBorderColor, width: 1.5)
              : Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 1.0,
                ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeBorderColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Team indicator dot (emerald for confirmed, amber for probable, muted when inactive)
            Container(
              width: 7.5,
              height: 7.5,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),

            // Team Name
            Flexible(
              child: Text(
                displayName,
                style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                      : (isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Formation Pill or Unavailable Badge
            if (team.formation != null && team.formation!.isNotEmpty) ...[
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeStatusColor.withValues(alpha: 0.22)
                      : (isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  team.formation!,
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? activeStatusColor
                        : (isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted),
                  ),
                ),
              ),
            ] else if (!hasLineup) ...[
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.08))
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.08),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  isArabic ? 'غير معلنة' : 'Unavailable',
                  style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Floating badge inside pitch showing active team name and formation.
  Widget _buildFloatingHeader({
    required TeamLineupEntity team,
    required bool isHome,
    required Color ringColor,
    required bool isArabic,
  }) {
    final displayName = team.displayName.isNotEmpty
        ? team.displayName
        : (team.teamName ?? (isHome ? 'Home' : 'Away'));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Team Name Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ringColor.withValues(alpha: 0.6),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (team.formation != null && team.formation!.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: ringColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    team.formation!,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: ringColor,
                    ),
                  ),
                ),
              ] else if (team.startingXi.isEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isArabic ? 'غير معلنة' : 'Unavailable',
                    style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Coach info (if available)
        if (team.coach != null &&
            team.coach!.name != null &&
            team.coach!.name!.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sports_rounded, size: 12, color: ringColor),
                const SizedBox(width: 4),
                Text(
                  team.coach!.name!,
                  style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Tactical board layout for a single team attacking UP (GK at bottom, Strikers at top).
  Widget _buildSingleTeamPitch({
    required TeamLineupEntity team,
    required TeamLineupEntity otherTeam,
    required bool isHome,
    required bool isDark,
    required bool isArabic,
  }) {
    // If this team has no starting XI announced, show an elegant empty state overlay
    if (team.startingXi.isEmpty) {
      final otherHasLineup = otherTeam.startingXi.isNotEmpty;
      final teamName = team.displayName.isNotEmpty
          ? team.displayName
          : (team.teamName ??
                (isHome
                    ? (isArabic ? 'صاحب الأرض' : 'Home')
                    : (isArabic ? 'الضيف' : 'Away')));
      final otherName = otherTeam.displayName.isNotEmpty
          ? otherTeam.displayName
          : (otherTeam.teamName ??
                (!isHome
                    ? (isArabic ? 'صاحب الأرض' : 'Home')
                    : (isArabic ? 'الضيف' : 'Away')));

      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.80),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: const Icon(
                  Icons.group_off_rounded,
                  size: 24,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isArabic
                    ? 'لم يتم الإعلان عن التشكيلة'
                    : 'Lineup Not Announced',
                style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              Text(
                isArabic
                    ? 'تشكيلة $teamName غير متوفرة حالياً'
                    : 'Lineup for $teamName is not available yet',
                style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                  fontSize: 11.5,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              if (otherHasLineup) ...[
                const SizedBox(height: 14),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _onSelectTeam(isHome ? 1 : 0),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isArabic
                                ? Icons.arrow_back_rounded
                                : Icons.arrow_forward_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isArabic
                                ? 'عرض تشكيلة $otherName'
                                : 'View $otherName Lineup',
                            style:
                                (isArabic
                                ? GoogleFonts.cairo
                                : GoogleFonts.inter)(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final rows = _groupSingleTeamTacticalRows(team);

    return Padding(
      padding: const EdgeInsets.only(
        top: 36.0,
        bottom: 12.0,
        left: 8.0,
        right: 8.0,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: rows.map((rowPlayers) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: rowPlayers.map((player) {
                return PitchPlayerNode(player: player, isHome: isHome);
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Partitions a team's starting XI into tactical rows from Top (Strikers) to Bottom (Goalkeeper).
  ///
  /// Team attacks UPwards:
  ///   Row 0: Forwards / Strikers (near opponent's goal)
  ///   Row 1: Attacking Midfielders
  ///   Row 2: Defensive Midfielders
  ///   Row 3: Defenders
  ///   Row 4: Goalkeeper (defending bottom goal)
  static List<List<LineupPlayerEntity>> _groupSingleTeamTacticalRows(
    TeamLineupEntity team,
  ) {
    final starters = List<LineupPlayerEntity>.from(team.startingXi);
    if (starters.isEmpty) return [];

    // 1. Isolate Goalkeepers & Outfield
    final gkList = <LineupPlayerEntity>[];
    final outfield = <LineupPlayerEntity>[];

    for (final p in starters) {
      if (p.isGoalkeeper || p.positionCode == 'G') {
        gkList.add(p);
      } else {
        outfield.add(p);
      }
    }

    // Sort outfield tactically first: Defenders -> Midfielders -> Forwards
    outfield.sort((a, b) {
      final wA = _tacticalLineWeight(a);
      final wB = _tacticalLineWeight(b);
      if (wA != wB) return wA.compareTo(wB);
      return (a.formationPosition ?? 0).compareTo(b.formationPosition ?? 0);
    });

    // 2. Parse formation numbers from API response (e.g. "4-2-3-1" -> [4, 2, 3, 1])
    final formationCounts = _parseFormationCounts(team.formation);
    final tacticalLines = <List<LineupPlayerEntity>>[];

    if (formationCounts != null && formationCounts.isNotEmpty) {
      int currentIndex = 0;
      for (final count in formationCounts) {
        if (currentIndex >= outfield.length) break;
        final take = (currentIndex + count <= outfield.length)
            ? count
            : outfield.length - currentIndex;
        final line = outfield.sublist(currentIndex, currentIndex + take);
        if (line.isNotEmpty) {
          line.sort(
            (a, b) =>
                (a.formationPosition ?? 0).compareTo(b.formationPosition ?? 0),
          );
          tacticalLines.add(line);
        }
        currentIndex += take;
      }
      if (currentIndex < outfield.length) {
        final leftover = outfield.sublist(currentIndex);
        leftover.sort(
          (a, b) =>
              (a.formationPosition ?? 0).compareTo(b.formationPosition ?? 0),
        );
        if (tacticalLines.isNotEmpty) {
          tacticalLines.last.addAll(leftover);
        } else {
          tacticalLines.add(leftover);
        }
      }
    } else {
      // Fallback: Group outfield by positionCode (D, M, F)
      final defenders = outfield.where((p) => p.positionCode == 'D').toList();
      final midfielders = outfield.where((p) => p.positionCode == 'M').toList();
      final forwards = outfield
          .where(
            (p) =>
                p.positionCode == 'F' ||
                p.positionCode == 'S' ||
                (!defenders.contains(p) && !midfielders.contains(p)),
          )
          .toList();

      defenders.sort(
        (a, b) =>
            (a.formationPosition ?? 0).compareTo(b.formationPosition ?? 0),
      );
      midfielders.sort(
        (a, b) =>
            (a.formationPosition ?? 0).compareTo(b.formationPosition ?? 0),
      );
      forwards.sort(
        (a, b) =>
            (a.formationPosition ?? 0).compareTo(b.formationPosition ?? 0),
      );

      if (defenders.isNotEmpty) tacticalLines.add(defenders);
      if (midfielders.isNotEmpty) tacticalLines.add(midfielders);
      if (forwards.isNotEmpty) tacticalLines.add(forwards);

      if (tacticalLines.isEmpty && outfield.isNotEmpty) {
        tacticalLines.add(outfield);
      }
    }

    // Outfield tacticalLines are ordered Defenders -> Midfielders -> Strikers.
    // Order for Column (Top to Bottom):
    //   Row 0 (Top): Strikers (tacticalLines.last)
    //   ...
    //   Row N-1: Defenders (tacticalLines.first)
    //   Row N (Bottom): Goalkeeper
    final rows = <List<LineupPlayerEntity>>[];
    for (int i = tacticalLines.length - 1; i >= 0; i--) {
      rows.add(tacticalLines[i]);
    }
    if (gkList.isNotEmpty) {
      rows.add(gkList);
    }
    return rows;
  }

  static List<int>? _parseFormationCounts(String? formation) {
    if (formation == null) return null;
    final clean = formation.trim();
    if (!RegExp(r'^\d(-\d)+$').hasMatch(clean)) return null;

    try {
      final numbers = clean.split('-').map((s) => int.parse(s.trim())).toList();
      if (numbers.isNotEmpty && numbers.every((n) => n > 0 && n <= 6)) {
        return numbers;
      }
    } catch (_) {}
    return null;
  }

  static int _tacticalLineWeight(LineupPlayerEntity p) {
    if (p.positionCode == 'D') return 1;
    if (p.positionCode == 'M') return 2;
    if (p.positionCode == 'F' || p.positionCode == 'S') return 3;
    final pos = (p.position ?? '').toLowerCase();
    if (pos.contains('دفاع') ||
        pos.contains('ظهير') ||
        pos.contains('back') ||
        pos.contains('defender') ||
        pos == 'cb' ||
        pos == 'lb' ||
        pos == 'rb') {
      return 1;
    }
    if (pos.contains('وسط') ||
        pos.contains('midfield') ||
        pos == 'cdm' ||
        pos == 'cm' ||
        pos == 'cam') {
      return 2;
    }
    if (pos.contains('هجوم') ||
        pos.contains('جناح') ||
        pos.contains('forward') ||
        pos.contains('striker') ||
        pos == 'cf' ||
        pos == 'st' ||
        pos == 'lw' ||
        pos == 'rw') {
      return 3;
    }
    return 2;
  }
}
