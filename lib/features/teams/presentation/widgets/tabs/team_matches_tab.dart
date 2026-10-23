import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/storage/local_storage_service.dart';
import '../../../../../core/widgets/empty_view.dart';
import '../../../../../core/widgets/section_header.dart';
import '../../../../matches/presentation/bloc/matches_bloc.dart';
import '../../../../matches/presentation/widgets/match_card.dart';
import '../../bloc/team_state.dart';

class TeamMatchesTab extends StatelessWidget {
  final TeamState state;
  final bool isDark;
  final bool isArabic;

  const TeamMatchesTab({
    super.key,
    required this.state,
    required this.isDark,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    String? timeFormat;
    try {
      timeFormat = context.select<MatchesBloc, String?>(
        (bloc) => bloc.state.timeFormat,
      );
    } catch (_) {
      try {
        if (sl.isRegistered<LocalStorageService>()) {
          timeFormat = sl<LocalStorageService>().getTimeFormat();
        }
      } catch (_) {}
    }

    final profile = state.profile;
    final online = profile?.onlineMatches ?? [];
    final upcoming = profile?.upcomingMatches ?? [];
    final recent = profile?.recentMatches ?? [];

    if (online.isEmpty && upcoming.isEmpty && recent.isEmpty) {
      return EmptyView(
        titleKey: 'tab_overview',
        customMessage: isArabic
            ? 'لا توجد مباريات مسجلة لهذا الفريق حاليًا'
            : 'No matches currently recorded for this team',
        icon: Icons.sports_soccer_rounded,
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: AppDimensions.xxxl, top: 8),
      children: [
        // 1. Live Matches (if any)
        if (online.isNotEmpty) ...[
          SectionHeader(
            title: isArabic ? 'مباريات جارية الآن' : 'Live Matches',
          ),
          ...online.map((m) => MatchCard(match: m, timeFormat: timeFormat)),
          const SizedBox(height: 12),
        ],

        // 2. Upcoming Fixtures
        if (upcoming.isNotEmpty) ...[
          SectionHeader(
            title: isArabic ? 'المباريات القادمة' : 'Upcoming Fixtures',
          ),
          ...upcoming.map((m) => MatchCard(match: m, timeFormat: timeFormat)),
          const SizedBox(height: 12),
        ],

        // 3. Finished Results
        if (recent.isNotEmpty) ...[
          SectionHeader(title: isArabic ? 'النتائج السابقة' : 'Past Results'),
          ...recent.map((m) => MatchCard(match: m, timeFormat: timeFormat)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
