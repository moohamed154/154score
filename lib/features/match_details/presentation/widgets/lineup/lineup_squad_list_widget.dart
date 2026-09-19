import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'package:ysscores/core/constants/app_colors.dart';
import 'package:ysscores/core/constants/app_dimensions.dart';
import 'package:ysscores/core/constants/app_typography.dart';
import 'package:ysscores/core/localization/app_localizations.dart';
import 'package:ysscores/core/widgets/app_image.dart';
import 'package:ysscores/features/match_details/domain/entities/match_details_entity.dart';

/// Detailed list view of Starting XI, Substitutes bench, Coaches, and Injuries.
class LineupSquadListWidget extends StatefulWidget {
  final TeamLineupEntity home;
  final TeamLineupEntity away;
  final int? selectedTeamIndex;
  final ValueChanged<int>? onTeamChanged;
  final bool showTeamSwitcher;
  final bool showStarters;

  const LineupSquadListWidget({
    super.key,
    required this.home,
    required this.away,
    this.selectedTeamIndex,
    this.onTeamChanged,
    this.showTeamSwitcher = true,
    this.showStarters = true,
  });

  @override
  State<LineupSquadListWidget> createState() => _LineupSquadListWidgetState();
}

class _LineupSquadListWidgetState extends State<LineupSquadListWidget> {
  int _internalTeamIndex = 0;

  int get _selectedTeamIndex => widget.selectedTeamIndex ?? _internalTeamIndex;

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
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.isArabic;
    final hMargin = AppDimensions.getHorizontalMargin(context);

    final currentTeam = _selectedTeamIndex == 0 ? widget.home : widget.away;
    final isHome = _selectedTeamIndex == 0;

    final subbedInPlayers =
        currentTeam.substitutes.where((p) => p.substituteIn).toList();
    final benchPlayers =
        currentTeam.substitutes.where((p) => !p.substituteIn).toList();

    return Column(
      children: [
        // Team Segmented Tab Switcher
        if (widget.showTeamSwitcher)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hMargin, vertical: 8),
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
              child: Row(
                children: [
                  Expanded(
                    child: _buildTeamTabItem(
                      title: widget.home.displayName.isNotEmpty
                          ? widget.home.displayName
                          : (widget.home.teamName ??
                              (isArabic ? 'صاحب الأرض' : 'Home')),
                      formation: widget.home.formation,
                      isSelected: _selectedTeamIndex == 0,
                      isDark: isDark,
                      isArabic: isArabic,
                      onTap: () => _onSelectTeam(0),
                    ),
                  ),
                  Expanded(
                    child: _buildTeamTabItem(
                      title: widget.away.displayName.isNotEmpty
                          ? widget.away.displayName
                          : (widget.away.teamName ??
                              (isArabic ? 'الضيف' : 'Away')),
                      formation: widget.away.formation,
                      isSelected: _selectedTeamIndex == 1,
                      isDark: isDark,
                      isArabic: isArabic,
                      onTap: () => _onSelectTeam(1),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Squad Content
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hMargin, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Starting XI Section (Shown only in list view, hidden below pitch)
              if (widget.showStarters &&
                  currentTeam.startingXi.isNotEmpty) ...[
                _buildSectionHeader(
                  title: isArabic ? 'التشكيلة الأساسية' : 'Starting XI',
                  count: currentTeam.startingXi.length,
                  isDark: isDark,
                  isArabic: isArabic,
                  icon: Icons.people_alt_rounded,
                  accentColor: AppColors.primary,
                ),
                const SizedBox(height: 8),
                ...currentTeam.startingXi.map(
                  (p) => _buildPlayerListTile(
                    player: p,
                    isDark: isDark,
                    isArabic: isArabic,
                    isHome: isHome,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 2. Coach (Shown at top when below pitch, or after starters in list view)
              if (!widget.showStarters && currentTeam.coach != null) ...[
                _buildCoachCard(
                  coach: currentTeam.coach!,
                  isDark: isDark,
                  isArabic: isArabic,
                  l10n: l10n,
                ),
                const SizedBox(height: 12),
              ],

              // 3. Substitutions Section (Players who were substituted in)
              if (subbedInPlayers.isNotEmpty) ...[
                _buildSectionHeader(
                  title: isArabic ? 'التبديلات' : 'Substitutions',
                  count: subbedInPlayers.length,
                  isDark: isDark,
                  isArabic: isArabic,
                  icon: Icons.swap_horiz_rounded,
                  accentColor: const Color(0xFF10B981),
                ),
                const SizedBox(height: 8),
                ...subbedInPlayers.map(
                  (p) => _buildSubstitutionCard(
                    playerIn: p,
                    team: currentTeam,
                    isDark: isDark,
                    isArabic: isArabic,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 4. Bench Section (Unused substitutes)
              if (benchPlayers.isNotEmpty) ...[
                _buildSectionHeader(
                  title: isArabic ? 'دكة البدلاء' : 'Bench',
                  count: benchPlayers.length,
                  isDark: isDark,
                  isArabic: isArabic,
                  icon: Icons.airline_seat_recline_normal_rounded,
                  accentColor: Colors.amber,
                ),
                const SizedBox(height: 8),
                ...benchPlayers.map(
                  (p) => _buildBenchPlayerCard(
                    player: p,
                    isDark: isDark,
                    isArabic: isArabic,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 5. Coach (Shown after bench in list view)
              if (widget.showStarters && currentTeam.coach != null) ...[
                _buildCoachCard(
                  coach: currentTeam.coach!,
                  isDark: isDark,
                  isArabic: isArabic,
                  l10n: l10n,
                ),
                const SizedBox(height: 16),
              ],

              // 6. Absences & Injuries Section
              if (currentTeam.injuries.isNotEmpty) ...[
                _buildSectionHeader(
                  title: isArabic ? 'الغيابات والإصابات' : 'Absences & Injuries',
                  count: currentTeam.injuries.length,
                  isDark: isDark,
                  isArabic: isArabic,
                  icon: Icons.medical_services_outlined,
                  accentColor: Colors.redAccent,
                ),
                const SizedBox(height: 8),
                ...currentTeam.injuries.map(
                  (injury) => _buildInjuryListTile(
                    injury: injury,
                    isDark: isDark,
                    isArabic: isArabic,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamTabItem({
    required String title,
    String? formation,
    required bool isSelected,
    required bool isDark,
    required bool isArabic,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd - 1),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                title,
                style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? (isDark ? Colors.white : AppColors.primary)
                      : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (formation != null && formation.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? Colors.white12 : Colors.black12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  formation,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.black : Colors.white70,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required int count,
    required bool isDark,
    required bool isArabic,
    required IconData icon,
    required Color accentColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: accentColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTypography.getBodyLarge(
            isDark: isDark,
            isArabic: isArabic,
          ).copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: accentColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerListTile({
    required LineupPlayerEntity player,
    required bool isDark,
    required bool isArabic,
    required bool isHome,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        onTap: () {
          final cleanName = player.name.trim();
          if (cleanName.isNotEmpty) {
            final pId = player.playerId ?? '0';
            final slug = Uri.encodeComponent(
              cleanName.replaceAll(RegExp(r'\s+'), '-'),
            );
            context.push('/player/$pId/$slug');
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              // Jersey Number
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? AppColors.darkCardElevated
                          : AppColors.lightCardElevated,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  player.number != null ? '${player.number}' : '-',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Player Avatar
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipOval(
                    child: AppImage(
                      imageUrl: player.photo,
                      width: 34,
                      height: 34,
                      placeholderIcon: Icons.person,
                    ),
                  ),
                  if (player.isCaptain)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          isArabic ? 'ق' : 'C',
                          style: (isArabic
                              ? GoogleFonts.cairo
                              : GoogleFonts.outfit)(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Name and Position
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color:
                            isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (player.detailedPosition != null &&
                            player.detailedPosition!.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkCardElevated
                                  : AppColors.lightCardElevated,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              player.detailedPosition!,
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
                        Flexible(
                          child: Text(
                            player.position ??
                                (player.isGoalkeeper
                                    ? (isArabic ? 'حارس المرمى' : 'Goalkeeper')
                                    : '-'),
                            style: (isArabic
                                ? GoogleFonts.cairo
                                : GoogleFonts.inter)(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // In-game stats badges (goals, own goals, cards, substitutions)
              if (player.goals > 0 ||
                  player.ownGoals > 0 ||
                  player.yellowCards > 0 ||
                  player.redCards > 0 ||
                  player.substituteIn ||
                  player.substituteOut) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (player.goals > 0) ...[
                      const Text('⚽', style: TextStyle(fontSize: 11)),
                      if (player.goals > 1)
                        Text(
                          '${player.goals}',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(width: 4),
                    ],
                    if (player.ownGoals > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.redCard.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          isArabic ? 'هدف ذاتي' : 'OG',
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.redCard,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (player.yellowCards > 0) ...[
                      Container(
                        width: 7,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.yellowCard,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (player.redCards > 0) ...[
                      Container(
                        width: 7,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.redCard,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (player.substituteIn) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.arrow_upward_rounded,
                            size: 13,
                            color: Color(0xFF10B981),
                          ),
                          if (player.substituteTime != null)
                            Text(
                              "${player.substituteTime}'",
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (player.substituteOut) ...[
                      const Icon(
                        Icons.arrow_downward_rounded,
                        size: 13,
                        color: AppColors.redCard,
                      ),
                      const SizedBox(width: 4),
                    ],
                  ],
                ),
                const SizedBox(width: 6),
              ],

              // Man of the Match Star
              if (player.isManOfMatch) ...[
                const Icon(
                  Icons.star_rounded,
                  size: 18,
                  color: Color(0xFFFFD700),
                ),
                const SizedBox(width: 4),
              ],

              // Rating Badge (if present, only for players who actually played)
              if (player.rating != null &&
                  player.rating!.isNotEmpty &&
                  (!player.isSubstitute || player.substituteIn)) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _getRatingColor(player.rating!),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    player.rating!,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _resolveSubbedOutName(
    LineupPlayerEntity playerIn,
    TeamLineupEntity team,
    bool isArabic,
  ) {
    if (playerIn.subbedForName != null &&
        playerIn.subbedForName!.trim().isNotEmpty) {
      return playerIn.subbedForName!.trim();
    }
    if (playerIn.subbedForId != null) {
      for (final s in team.startingXi) {
        if (s.playerId == playerIn.subbedForId) {
          return s.displayName;
        }
      }
    }
    if (playerIn.substituteTime != null) {
      for (final s in team.startingXi) {
        if (s.substituteOut && s.substituteTime == playerIn.substituteTime) {
          return s.displayName;
        }
      }
    }
    final subbedOutStarters =
        team.startingXi.where((s) => s.substituteOut).toList();
    if (subbedOutStarters.isNotEmpty) {
      final subbedInSubs =
          team.substitutes.where((s) => s.substituteIn).toList();
      final idx = subbedInSubs.indexOf(playerIn);
      if (idx != -1 && idx < subbedOutStarters.length) {
        return subbedOutStarters[idx].displayName;
      }
    }
    return isArabic ? 'لاعب مستبدل' : 'Substituted Player';
  }

  Widget _buildSubstitutionCard({
    required LineupPlayerEntity playerIn,
    required TeamLineupEntity team,
    required bool isDark,
    required bool isArabic,
  }) {
    final subbedOutName = _resolveSubbedOutName(playerIn, team, isArabic);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          final cleanName = playerIn.name.trim();
          if (cleanName.isNotEmpty) {
            final pId = playerIn.playerId ?? '0';
            final slug = Uri.encodeComponent(
              cleanName.replaceAll(RegExp(r'\s+'), '-'),
            );
            context.push('/player/$pId/$slug');
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131A2A) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              // Avatar Stack with Jersey Number and Rating
              SizedBox(
                width: 44,
                height: 48,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AppImage(
                        imageUrl: playerIn.photo,
                        width: 40,
                        height: 40,
                        placeholderIcon: Icons.person,
                      ),
                    ),
                    if (playerIn.number != null)
                      Positioned(
                        top: -3,
                        left: -2,
                        child: Text(
                          '${playerIn.number}',
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    if (playerIn.rating != null &&
                        playerIn.rating!.isNotEmpty &&
                        playerIn.rating != '0' &&
                        playerIn.rating != '-')
                      Positioned(
                        bottom: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: _getRatingColor(playerIn.rating!),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            playerIn.rating!,
                            style: GoogleFonts.outfit(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Player IN (green) and Player OUT (red)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // IN Row
                    Row(
                      children: [
                        Icon(
                          isArabic
                              ? Icons.arrow_back_rounded
                              : Icons.arrow_forward_rounded,
                          size: 15,
                          color: const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            playerIn.displayName,
                            style: (isArabic
                                ? GoogleFonts.cairo
                                : GoogleFonts.inter)(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF34D399),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    // OUT Row
                    Row(
                      children: [
                        Icon(
                          isArabic
                              ? Icons.arrow_forward_rounded
                              : Icons.arrow_back_rounded,
                          size: 15,
                          color: const Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            subbedOutName,
                            style: (isArabic
                                ? GoogleFonts.cairo
                                : GoogleFonts.inter)(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFEF4444),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Trailing: In-game event badges & substitution minute
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (playerIn.goals > 0) ...[
                    const Text('⚽', style: TextStyle(fontSize: 12)),
                    if (playerIn.goals > 1)
                      Text(
                        ' x${playerIn.goals}',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(width: 6),
                  ],
                  if (playerIn.assists > 0) ...[
                    const Text('👟', style: TextStyle(fontSize: 12)),
                    if (playerIn.assists > 1)
                      Text(
                        ' x${playerIn.assists}',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(width: 6),
                  ],
                  if (playerIn.yellowCards > 0) ...[
                    Container(
                      width: 8,
                      height: 11,
                      decoration: BoxDecoration(
                        color: AppColors.yellowCard,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (playerIn.redCards > 0) ...[
                    Container(
                      width: 8,
                      height: 11,
                      decoration: BoxDecoration(
                        color: AppColors.redCard,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (playerIn.substituteTime != null)
                    Text(
                      "${playerIn.substituteTime}'",
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenchPlayerCard({
    required LineupPlayerEntity player,
    required bool isDark,
    required bool isArabic,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          final cleanName = player.name.trim();
          if (cleanName.isNotEmpty) {
            final pId = player.playerId ?? '0';
            final slug = Uri.encodeComponent(
              cleanName.replaceAll(RegExp(r'\s+'), '-'),
            );
            context.push('/player/$pId/$slug');
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131A2A) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              // Avatar Stack with Jersey Number (no rating for unused bench players)
              SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AppImage(
                        imageUrl: player.photo,
                        width: 40,
                        height: 40,
                        placeholderIcon: Icons.person,
                      ),
                    ),
                    if (player.number != null)
                      Positioned(
                        top: -3,
                        left: -2,
                        child: Text(
                          '${player.number}',
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Player Name & Position
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      player.displayName,
                      style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (player.detailedPosition != null &&
                        player.detailedPosition!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        player.detailedPosition!,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Cards if received while on bench
              if (player.yellowCards > 0 || player.redCards > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (player.yellowCards > 0) ...[
                      Container(
                        width: 8,
                        height: 11,
                        decoration: BoxDecoration(
                          color: AppColors.yellowCard,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (player.redCards > 0)
                      Container(
                        width: 8,
                        height: 11,
                        decoration: BoxDecoration(
                          color: AppColors.redCard,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoachCard({
    required LineupCoachEntity coach,
    required bool isDark,
    required bool isArabic,
    required AppLocalizations l10n,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: isArabic ? 'المدرب' : 'Coach',
          count: 1,
          isDark: isDark,
          isArabic: isArabic,
          icon: Icons.sports,
          accentColor:
              isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              final cleanName = coach.name?.trim() ?? '';
              if (cleanName.isNotEmpty) {
                final slug = Uri.encodeComponent(
                  cleanName.replaceAll(RegExp(r'\s+'), '-'),
                );
                context.push('/player/0/$slug');
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131A2A) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AppImage(
                      imageUrl: coach.photo,
                      width: 40,
                      height: 40,
                      placeholderIcon: Icons.sports,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (coach.name != null && coach.name!.isNotEmpty)
                              ? coach.name!
                              : (isArabic ? 'المدير الفني' : 'Coach'),
                          style: (isArabic
                              ? GoogleFonts.cairo
                              : GoogleFonts.inter)(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isArabic ? 'المدرب الفني' : 'Head Coach',
                          style: (isArabic
                              ? GoogleFonts.cairo
                              : GoogleFonts.inter)(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInjuryListTile({
    required LineupInjuryEntity injury,
    required bool isDark,
    required bool isArabic,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AppImage(
                    imageUrl: injury.photo,
                    width: 40,
                    height: 40,
                    placeholderIcon: Icons.person,
                  ),
                ),
                if (injury.number != null)
                  Positioned(
                    top: -3,
                    left: -2,
                    child: Text(
                      '${injury.number}',
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  injury.displayName,
                  style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (injury.position != null && injury.position!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    injury.position!,
                    style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.healing, size: 12, color: Colors.redAccent),
                const SizedBox(width: 4),
                Text(
                  injury.absenceReason ?? (isArabic ? 'غياب' : 'Absent'),
                  style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Color _getRatingColor(String ratingStr) {
    final val = double.tryParse(ratingStr);
    if (val == null) return AppColors.primary;
    if (val >= 7.2) return const Color(0xFF16A34A);
    if (val >= 6.2) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }
}
