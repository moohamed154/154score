import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/widgets/empty_view.dart';
import '../../../../../core/widgets/error_view.dart';
import '../../../../leagues/presentation/bloc/league_bloc.dart';
import '../../../../leagues/presentation/bloc/league_event.dart';
import '../../../../leagues/presentation/bloc/league_state.dart';
import '../../../../leagues/presentation/widgets/top_scorers_table.dart';
import 'match_details_skeletons.dart';

class MatchScorersTab extends StatelessWidget {
  final String? leagueId;
  final LeagueBloc? leagueBloc;
  final bool isAssists;
  final bool isDark;
  final bool isArabic;

  const MatchScorersTab({
    super.key,
    required this.leagueId,
    required this.leagueBloc,
    this.isAssists = false,
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLeagueId = leagueId;
    if (effectiveLeagueId == null || effectiveLeagueId.isEmpty) {
      return _buildNoLeagueDataView(
        message: isAssists
            ? (isArabic
                ? 'بيانات الصناع غير متوفرة لهذه البطولة حالياً'
                : 'Top assists not available for this competition')
            : (isArabic
                ? 'بيانات الهدافين غير متوفرة لهذه البطولة حالياً'
                : 'Top scorers not available for this competition'),
      );
    }

    final bloc = leagueBloc;
    if (bloc == null) {
      return MatchDetailsSkeletons.buildScorersSkeleton(
        isDark: isDark,
        isArabic: isArabic,
      );
    }

    return BlocBuilder<LeagueBloc, LeagueState>(
      bloc: bloc,
      builder: (context, state) {
        final items = isAssists ? state.topAssists : state.topScorers;

        if (state.status == LeagueStatus.loading && items.isEmpty) {
          return MatchDetailsSkeletons.buildScorersSkeleton(
            isDark: isDark,
            isArabic: isArabic,
          );
        }

        if (state.status == LeagueStatus.error && items.isEmpty) {
          return ErrorView(
            message: state.errorMessage,
            onRetry: () => bloc.add(
              LoadLeagueDetailsEvent(effectiveLeagueId, isRefresh: true),
            ),
          );
        }

        Future<void> refreshData() async {
          final completer = Completer<void>();
          bloc.add(
            LoadLeagueDetailsEvent(
              effectiveLeagueId,
              isRefresh: true,
              completer: completer,
            ),
          );
          try {
            await completer.future.timeout(const Duration(seconds: 4));
          } catch (_) {}
        }

        if (items.isEmpty) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: refreshData,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                EmptyView(
                  titleKey: 'tab_overview',
                  customMessage: isAssists
                      ? (isArabic
                          ? 'لا توجد بيانات للصناع حالياً'
                          : 'No top assists available for this competition')
                      : (isArabic
                          ? 'لا توجد بيانات للهدافين حالياً'
                          : 'No top scorers available for this competition'),
                  icon: Icons.emoji_events_outlined,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: refreshData,
          child: ListView(
            key: PageStorageKey(
              isAssists ? 'match_assists_tab_list' : 'match_scorers_tab_list',
            ),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              TopScorersTable(scorers: items, isAssists: isAssists),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoLeagueDataView({required String message}) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.emoji_events_outlined,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: AppTypography.getBodyLarge(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
