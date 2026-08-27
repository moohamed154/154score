import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../bloc/standings_bloc.dart';
import '../widgets/standings_table.dart';

class StandingsView extends StatefulWidget {
  final String? initialLeagueId;

  const StandingsView({super.key, this.initialLeagueId});

  @override
  State<StandingsView> createState() => _StandingsViewState();
}

class _StandingsViewState extends State<StandingsView> {
  final List<(String, String, String)> _popularLeagues = [
    ('937599', 'Premier League', 'الدوري الإنجليزي'),
    ('938652', 'LaLiga', 'الدوري الإسباني'),
    ('936357', 'Serie A', 'الدوري الإيطالي'),
    ('938769', 'Bundesliga', 'الدوري الألماني'),
    ('937873', 'Ligue 1', 'الدوري الفرنسي'),
    ('904988', 'UEFA Champions League', 'دوري أبطال أوروبا'),
    ('943009', 'Egyptian League', 'الدوري المصري'),
    ('941825', 'Saudi Pro League', 'دوري روشن السعودي'),
  ];

  @override
  void initState() {
    super.initState();
    final bloc = context.read<StandingsBloc>();
    final targetId = widget.initialLeagueId ?? bloc.state.selectedLeagueId;
    bloc.add(LoadStandingsEvent(targetId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('standings_title'))),
      body: BlocBuilder<StandingsBloc, StandingsState>(
        builder: (context, state) {
          return Column(
            children: [
              // League Selector Chips
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.lg,
                  ),
                  itemCount: _popularLeagues.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final item = _popularLeagues[index];
                    final isSelected = state.selectedLeagueId == item.$1;
                    final title = isArabic ? item.$3 : item.$2;

                    return ChoiceChip(
                      showCheckmark: false,
                      selected: isSelected,
                      onSelected: (_) {
                        context.read<StandingsBloc>().add(
                          LoadStandingsEvent(item.$1),
                        );
                      },
                      backgroundColor: isDark
                          ? AppColors.darkCard
                          : AppColors.lightCard,
                      selectedColor: AppColors.primary,
                      side: BorderSide(
                        color: isSelected
                            ? Colors.transparent
                            : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull,
                        ),
                      ),
                      label: Text(
                        title,
                        style:
                            AppTypography.getBodySmall(
                              isDark: isDark,
                              isArabic: isArabic,
                            ).copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.black
                                  : (isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary),
                            ),
                      ),
                    );
                  },
                ),
              ),

              // Standings Content
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    context.read<StandingsBloc>().add(
                      LoadStandingsEvent(state.selectedLeagueId),
                    );
                  },
                  child: _buildBody(context, state, isArabic),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, StandingsState state, bool isArabic) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.status == StandingsStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.status == StandingsStatus.error) {
      return ErrorView(
        message: state.errorMessage,
        onRetry: () {
          context.read<StandingsBloc>().add(
            LoadStandingsEvent(state.selectedLeagueId),
          );
        },
      );
    }

    if (state.standings == null || state.standings!.rows.isEmpty) {
      return EmptyView(
        titleKey: 'standings_title',
        customMessage: isArabic
            ? 'لا يوجد جدول ترتيب متوفر لهذه البطولة حالياً'
            : 'No standings data available for this competition',
        icon: Icons.table_chart_outlined,
      );
    }

    final standings = state.standings!;
    final hasGroups = standings.hasMultipleGroups;

    return ListView(
      padding: const EdgeInsets.only(bottom: AppDimensions.xxxl),
      children: [
        if (hasGroups) ...[
          ...standings.groups!.entries.map((groupEntry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    groupEntry.key,
                    style: AppTypography.getHeadingMedium(
                      isDark: isDark,
                      isArabic: isArabic,
                    ).copyWith(fontSize: 16),
                  ),
                ),
                StandingsTable(rows: groupEntry.value),
              ],
            );
          }),
        ] else ...[
          StandingsTable(rows: standings.rows),
        ],

        // Qualification Legend
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.xl,
            vertical: 8,
          ),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendItem(
                AppColors.uclGreen,
                isArabic ? 'دوري أبطال أوروبا' : 'Champions League',
                isDark,
              ),
              _buildLegendItem(
                AppColors.uelBlue,
                isArabic ? 'الدوري الأوروبي' : 'Europa League',
                isDark,
              ),
              _buildLegendItem(
                AppColors.relegationRed,
                isArabic ? 'الهبوط' : 'Relegation',
                isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
      ],
    );
  }
}
