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

  const LineupSquadListWidget({
    super.key,
    required this.home,
    required this.away,
    this.selectedTeamIndex,
    this.onTeamChanged,
    this.showTeamSwitcher = true,
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

    return Column(
      children: [
        // Team Segmented Tab Switcher
        if (widget.showTeamSwitcher)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hMargin, vertical: 8),
            child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
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
                        : (widget.home.teamName ?? (isArabic ? 'صاحب الأرض' : 'Home')),
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
                        : (widget.away.teamName ?? (isArabic ? 'الضيف' : 'Away')),
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
              // Coach / Manager Card (if present)
              if (currentTeam.coach != null)
                _buildCoachCard(
                  coach: currentTeam.coach!,
                  isDark: isDark,
                  isArabic: isArabic,
                  l10n: l10n,
                ),

              const SizedBox(height: 12),

              // Starting XI Section
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

              const SizedBox(height: 20),

              // Substitutes Section
              if (currentTeam.substitutes.isNotEmpty) ...[
                _buildSectionHeader(
                  title: isArabic ? 'دكة البدلاء' : 'Substitutes',
                  count: currentTeam.substitutes.length,
                  isDark: isDark,
                  isArabic: isArabic,
                  icon: Icons.airline_seat_recline_normal_rounded,
                  accentColor: Colors.amber,
                ),
                const SizedBox(height: 8),
                ...currentTeam.substitutes.map(
                  (p) => _buildPlayerListTile(
                    player: p,
                    isDark: isDark,
                    isArabic: isArabic,
                    isHome: isHome,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Absences & Injuries Section
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
                    Text(
                      player.position ??
                          (player.isGoalkeeper
                              ? (isArabic ? 'حارس المرمى' : 'Goalkeeper')
                              : '-'),
                      style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                        fontSize: 11,
                        color:
                            isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Rating Badge (if present)
              if (player.rating != null && player.rating!.isNotEmpty) ...[
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

  Widget _buildCoachCard({
    required LineupCoachEntity coach,
    required bool isDark,
    required bool isArabic,
    required AppLocalizations l10n,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
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
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              ClipOval(
                child: AppImage(
                  imageUrl: coach.photo,
                  width: 38,
                  height: 38,
                  placeholderIcon: Icons.sports,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (coach.name != null && coach.name!.isNotEmpty)
                          ? coach.name!
                          : (isArabic ? 'المدير الفني' : 'Coach'),
                      style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color:
                            isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isArabic ? 'المدرب الفني' : 'Head Coach',
                      style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                        fontSize: 11,
                        color:
                            isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.sports,
                  size: 16,
                  color: isDark ? AppColors.primary : AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInjuryListTile({
    required LineupInjuryEntity injury,
    required bool isDark,
    required bool isArabic,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: Colors.redAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          ClipOval(
            child: AppImage(
              imageUrl: injury.photo,
              width: 32,
              height: 32,
              placeholderIcon: Icons.person,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  injury.name,
                  style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  injury.position ?? '',
                  style: (isArabic ? GoogleFonts.cairo : GoogleFonts.inter)(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
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
