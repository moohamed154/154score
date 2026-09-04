import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ysscores/core/constants/app_colors.dart';
import 'package:ysscores/core/constants/app_dimensions.dart';
import 'package:ysscores/features/match_details/domain/entities/match_details_entity.dart';
import 'pitch_painter.dart';
import 'pitch_player_node.dart';

/// Interactive tactical pitch board displaying starting XI formations for both Home & Away teams.
class MatchPitchWidget extends StatelessWidget {
  final TeamLineupEntity home;
  final TeamLineupEntity away;

  const MatchPitchWidget({
    super.key,
    required this.home,
    required this.away,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = Directionality.of(context) == TextDirection.rtl;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: AppDimensions.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
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
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg - 1),
            child: AspectRatio(
              aspectRatio: 1 / 1.90,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Custom Football Turf & Line Markings
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: PitchPainter(isDark: isDark),
                    ),
                  ),

                  // 2. Team Formations Layout
                  Column(
                    children: [
                      // Away Team Half (Top Half, Goal at Top)
                      Expanded(
                        child: _buildTeamHalf(
                          team: away,
                          isHome: false,
                          isDark: isDark,
                          isArabic: isArabic,
                        ),
                      ),

                      // Halfway Line Inset Spacing
                      const SizedBox(height: 14),

                      // Home Team Half (Bottom Half, Goal at Bottom)
                      Expanded(
                        child: _buildTeamHalf(
                          team: home,
                          isHome: true,
                          isDark: isDark,
                          isArabic: isArabic,
                        ),
                      ),
                    ],
                  ),

                  // 3. Away Team Floating Banner (Top)
                  Positioned(
                    top: 10,
                    left: 12,
                    right: 12,
                    child: _buildTeamBadge(
                      team: away,
                      isHome: false,
                      isDark: isDark,
                      isArabic: isArabic,
                    ),
                  ),

                  // 4. Home Team Floating Banner (Bottom)
                  Positioned(
                    bottom: 10,
                    left: 12,
                    right: 12,
                    child: _buildTeamBadge(
                      team: home,
                      isHome: true,
                      isDark: isDark,
                      isArabic: isArabic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamBadge({
    required TeamLineupEntity team,
    required bool isHome,
    required bool isDark,
    required bool isArabic,
  }) {
    final ringColor = isHome
        ? const Color(0xFF10B981)
        : const Color(0xFF38BDF8);

    return Align(
      alignment: isHome ? Alignment.bottomCenter : Alignment.topCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(20),
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
              team.displayName.isNotEmpty
                  ? team.displayName
                  : (team.teamName ?? (isHome ? 'Home' : 'Away')),
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeamHalf({
    required TeamLineupEntity team,
    required bool isHome,
    required bool isDark,
    required bool isArabic,
  }) {
    final rows = _groupPlayersIntoTacticalRows(team, isHome: isHome);

    return Padding(
      padding: EdgeInsets.only(
        top: isHome ? 6.0 : 34.0,
        bottom: isHome ? 34.0 : 6.0,
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
                return PitchPlayerNode(
                  player: player,
                  isHome: isHome,
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Partitions the starting XI into rows ordered from top to bottom.
  ///
  /// For Away (top half):
  ///   Row 0: Goalkeeper (at top goal)
  ///   Row 1: Defenders
  ///   Row 2: Defensive Midfielders
  ///   Row 3+: Attacking Midfielders / Forwards (near center line)
  ///
  /// For Home (bottom half):
  ///   Row 0+: Forwards / Attacking Midfielders (near center line)
  ///   Row 1: Defensive Midfielders
  ///   Row 2: Defenders
  ///   Row 3: Goalkeeper (at bottom goal)
  static List<List<LineupPlayerEntity>> _groupPlayersIntoTacticalRows(
    TeamLineupEntity team, {
    required bool isHome,
  }) {
    final starters = List<LineupPlayerEntity>.from(team.startingXi);
    if (starters.isEmpty) return [];

    // 1. Isolate Goalkeepers
    final gkList = <LineupPlayerEntity>[];
    final outfield = <LineupPlayerEntity>[];

    for (final p in starters) {
      if (p.isGoalkeeper || p.positionCode == 'G') {
        gkList.add(p);
      } else {
        outfield.add(p);
      }
    }

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
          line.sort((a, b) => isHome
              ? (a.formationPosition ?? 0).compareTo(b.formationPosition ?? 0)
              : (b.formationPosition ?? 0).compareTo(a.formationPosition ?? 0));
          tacticalLines.add(line);
        }
        currentIndex += take;
      }
      if (currentIndex < outfield.length) {
        final leftover = outfield.sublist(currentIndex);
        leftover.sort((a, b) => isHome
            ? (a.formationPosition ?? 0).compareTo(b.formationPosition ?? 0)
            : (b.formationPosition ?? 0).compareTo(a.formationPosition ?? 0));
        if (tacticalLines.isNotEmpty) {
          tacticalLines.last.addAll(leftover);
        } else {
          tacticalLines.add(leftover);
        }
      }
    } else {
      // Fallback: Group outfield by positionCode (D, M, F)
      final defenders = outfield
          .where((p) => p.positionCode == 'D')
          .toList();
      final midfielders = outfield
          .where((p) => p.positionCode == 'M')
          .toList();
      final forwards = outfield
          .where((p) =>
              p.positionCode == 'F' ||
              p.positionCode == 'S' ||
              (!defenders.contains(p) && !midfielders.contains(p)))
          .toList();

      defenders.sort((a, b) => isHome
          ? (a.formationPosition ?? 0).compareTo(b.formationPosition ?? 0)
          : (b.formationPosition ?? 0).compareTo(a.formationPosition ?? 0));
      midfielders.sort((a, b) => isHome
          ? (a.formationPosition ?? 0).compareTo(b.formationPosition ?? 0)
          : (b.formationPosition ?? 0).compareTo(a.formationPosition ?? 0));
      forwards.sort((a, b) => isHome
          ? (a.formationPosition ?? 0).compareTo(b.formationPosition ?? 0)
          : (b.formationPosition ?? 0).compareTo(a.formationPosition ?? 0));

      if (defenders.isNotEmpty) tacticalLines.add(defenders);
      if (midfielders.isNotEmpty) tacticalLines.add(midfielders);
      if (forwards.isNotEmpty) tacticalLines.add(forwards);

      if (tacticalLines.isEmpty && outfield.isNotEmpty) {
        tacticalLines.add(outfield);
      }
    }

    if (isHome) {
      // Home Half (attacks UP): Forwards (nearest to center) -> Midfielders -> Defenders -> Goalkeeper (bottom)
      final homeRows = <List<LineupPlayerEntity>>[];
      for (int i = tacticalLines.length - 1; i >= 0; i--) {
        homeRows.add(tacticalLines[i]);
      }
      if (gkList.isNotEmpty) {
        homeRows.add(gkList);
      }
      return homeRows;
    } else {
      // Away Half (attacks DOWN): Goalkeeper (top) -> Defenders -> Midfielders -> Forwards (nearest to center)
      final awayRows = <List<LineupPlayerEntity>>[];
      if (gkList.isNotEmpty) {
        awayRows.add(gkList);
      }
      awayRows.addAll(tacticalLines);
      return awayRows;
    }
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
}
