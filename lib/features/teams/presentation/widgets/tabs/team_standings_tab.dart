import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/widgets/app_image.dart';
import '../../../../../core/widgets/empty_view.dart';
import '../../../../standings/domain/entities/standings_entity.dart';
import '../../../../standings/presentation/widgets/standings_table.dart';
import '../../bloc/team_bloc.dart';
import '../../bloc/team_event.dart';
import '../../bloc/team_state.dart';

class TeamStandingsTab extends StatelessWidget {
  final TeamState state;
  final bool isDark;
  final bool isArabic;
  final String displayName;

  const TeamStandingsTab({
    super.key,
    required this.state,
    required this.isDark,
    required this.isArabic,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    final championships = state.profile?.championships ?? [];
    final currentStandings = state.currentStandings;
    final hMargin = AppDimensions.getHorizontalMargin(context);

    return ListView(
      padding: const EdgeInsets.only(bottom: AppDimensions.xxxl, top: 8),
      children: [
        // Championship Selector Pills
        if (championships.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: hMargin),
              itemCount: championships.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final champ = championships[index];
                final champKey = champ.urlId ?? champ.id;
                final isSelected = state.selectedChampionshipId == champKey ||
                    (state.selectedChampionshipId == null && index == 0);

                return FilterChip(
                  avatar: champ.logo != null
                      ? AppImage(
                          imageUrl: champ.logo,
                          width: 18,
                          height: 18,
                          fit: BoxFit.contain,
                        )
                      : null,
                  label: Text(champ.title),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor:
                      isDark ? AppColors.darkCard : AppColors.lightCard,
                  checkmarkColor: Colors.white,
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                    ),
                  ),
                  onSelected: (_) {
                    context.read<TeamBloc>().add(
                          SelectChampionshipStandingsEvent(champKey),
                        );
                  },
                );
              },
            ),
          ),

        const SizedBox(height: 10),

        // Standings Loading or Content
        if (state.isStandingsLoading)
          Skeletonizer(
            enabled: true,
            child: StandingsTable(
              rows: List.generate(
                6,
                (index) => StandingRowEntity(
                  position: index + 1,
                  teamName: isArabic ? 'ريال مدريد' : 'Real Madrid',
                  played: 28,
                  wins: 21,
                  draws: 5,
                  losses: 2,
                  goalsFor: 62,
                  goalsAgainst: 20,
                  goalDiff: 42,
                  points: 68 - (index * 3),
                ),
              ),
              showFullStats: true,
            ),
          )
        else if (currentStandings != null && currentStandings.rows.isNotEmpty)
          StandingsTable(
            rows: currentStandings.rows,
            highlightedTeamName: displayName,
            showFullStats: true,
          )
        else if (state.profile?.standingsRow != null)
          StandingsTable(
            rows: [state.profile!.standingsRow!],
            highlightedTeamName: displayName,
            showFullStats: true,
          )
        else
          EmptyView(
            titleKey: 'tab_overview',
            customMessage: isArabic
                ? 'لا يتوفر جدول ترتيب لهذه البطولة حالياً'
                : 'No standings table available for this championship',
            icon: Icons.table_chart_outlined,
          ),
      ],
    );
  }
}
