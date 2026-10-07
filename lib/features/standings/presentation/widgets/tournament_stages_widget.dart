import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/entities/standings_entity.dart';

class TournamentStagesWidget extends StatefulWidget {
  final List<TournamentStageEntity> stages;

  const TournamentStagesWidget({super.key, required this.stages});

  @override
  State<TournamentStagesWidget> createState() => _TournamentStagesWidgetState();
}

class _TournamentStagesWidgetState extends State<TournamentStagesWidget> {
  int _selectedStageIndex = 0;

  @override
  void initState() {
    super.initState();
    // Default to the final round if available (last stage in list typically), or first
    if (widget.stages.isNotEmpty) {
      // If the list ends with 'النهائي' or 'Final', default to it; otherwise default to index 0
      final lastIndex = widget.stages.length - 1;
      final lastName = widget.stages[lastIndex].stageName.toLowerCase();
      if (lastName.contains('النهائي') || lastName.contains('final')) {
        _selectedStageIndex = lastIndex;
      } else {
        _selectedStageIndex = 0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stages.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;
    final hMargin = AppDimensions.getHorizontalMargin(context);

    // Ensure selected index is in bounds
    if (_selectedStageIndex >= widget.stages.length) {
      _selectedStageIndex = 0;
    }

    final currentStage = widget.stages[_selectedStageIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal Stages Pill Selector
        Container(
          height: 44,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: hMargin),
            scrollDirection: Axis.horizontal,
            itemCount: widget.stages.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final stage = widget.stages[index];
              final isSelected = index == _selectedStageIndex;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedStageIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                              ? AppColors.darkCardElevated
                              : AppColors.lightCardElevated),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      l10n.formatStageName(stage.stageName),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Stage Matches List
        if (currentStage.matches.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hMargin, vertical: 24),
            child: Center(
              child: Text(
                isArabic
                    ? 'لا توجد مباريات متاحة لهذا الدور'
                    : 'No matches available for this stage',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: hMargin, vertical: 6),
            itemCount: currentStage.matches.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, matchIdx) {
              final match = currentStage.matches[matchIdx];
              return _buildStageMatchCard(context, match, isDark, isArabic);
            },
          ),
      ],
    );
  }

  Widget _buildStageMatchCard(
    BuildContext context,
    StageMatchEntity match,
    bool isDark,
    bool isArabic,
  ) {
    final hasScore = match.teamA.score != null || match.teamB.score != null;
    final hasDateInfo =
        (match.matchDate != null && match.matchDate!.isNotEmpty) ||
        (match.position != null && match.position!.isNotEmpty);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          onTap: (match.matchId != null && match.matchId!.isNotEmpty)
              ? () => context.push('/match/${match.matchId}')
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              children: [
                if (hasDateInfo) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (match.position != null && match.position!.isNotEmpty)
                        Text(
                          match.position!,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      if (match.matchDate != null &&
                          match.matchDate!.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 11,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              match.matchDate!,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            if (match.matchTime != null &&
                                match.matchTime!.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                match.matchTime!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Divider(
                    height: 1,
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                  const SizedBox(height: 8),
                ],

                // Team A Row
                _buildTeamRow(
                  match.teamA,
                  isWinner:
                      match.teamA.isWinner ||
                      (match.winnerId != null &&
                          match.winnerId == match.teamA.id),
                  hasScore: hasScore,
                  isDark: isDark,
                  isArabic: isArabic,
                ),

                const SizedBox(height: 6),

                // Team B Row
                _buildTeamRow(
                  match.teamB,
                  isWinner:
                      match.teamB.isWinner ||
                      (match.winnerId != null &&
                          match.winnerId == match.teamB.id),
                  hasScore: hasScore,
                  isDark: isDark,
                  isArabic: isArabic,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamRow(
    StageTeamEntity team, {
    required bool isWinner,
    required bool hasScore,
    required bool isDark,
    required bool isArabic,
  }) {
    return Row(
      children: [
        // Winner Indicator Bar
        Container(
          width: 3,
          height: 20,
          decoration: BoxDecoration(
            color: isWinner ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),

        // Team Logo
        AppImage(
          imageUrl: team.logo,
          width: 24,
          height: 24,
          borderRadius: 4,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 10),

        // Team Name
        Expanded(
          child: Text(
            team.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
              color: isWinner
                  ? (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary)
                  : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
            ),
          ),
        ),

        // Score Badge
        if (hasScore && team.score != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: isWinner
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isWinner
                    ? AppColors.primary
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                width: isWinner ? 1.0 : 0.5,
              ),
            ),
            child: Text(
              '${team.score}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isWinner ? FontWeight.w800 : FontWeight.w600,
                color: isWinner
                    ? AppColors.primary
                    : (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary),
              ),
            ),
          ),
      ],
    );
  }
}
