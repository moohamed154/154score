import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:score154/core/localization/app_localizations.dart';
import 'package:score154/core/network/api_result.dart';
import 'package:score154/core/storage/local_storage_service.dart';
import 'package:score154/core/utils/league_resolver.dart';
import 'package:score154/core/widgets/app_image.dart';
import 'package:score154/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:score154/features/matches/domain/entities/match_entity.dart';
import 'package:score154/features/matches/presentation/widgets/match_card.dart';
import 'package:score154/features/teams/domain/entities/team_entity.dart';
import 'package:score154/features/teams/domain/repositories/teams_repository.dart';
import 'package:score154/features/teams/presentation/bloc/team_bloc.dart';
import 'package:score154/features/teams/presentation/views/team_view.dart';
import 'package:score154/features/teams/presentation/widgets/team_header_card.dart';

class _MockLocalStorageService implements LocalStorageService {
  final String lang;
  _MockLocalStorageService({this.lang = 'en'});

  @override
  Future<void> init() async {}
  @override
  String getLanguage() => lang;
  @override
  Future<bool> setLanguage(String langCode) async => true;
  @override
  String getThemeMode() => 'dark';
  @override
  Future<bool> setThemeMode(String themeMode) async => true;
  @override
  String getTimeFormat() => '24h';
  @override
  Future<bool> setTimeFormat(String format) async => true;
  @override
  List<String> getFavoriteMatches() => [];
  @override
  List<String> getFavoriteTeams() => [];
  @override
  bool isFavoriteTeam(String teamName, {String? id}) => false;
  @override
  Future<bool> toggleFavoriteTeam(String teamName, {String? id}) async => true;
  @override
  int getTimezoneOffset() => 0;
  @override
  Future<bool> setTimezoneOffset(int offset) async => true;
  @override
  bool isTimezoneAuto() => true;
  @override
  Future<bool> setTimezoneAuto(bool isAuto) async => true;
  @override
  int getDeviceTimezoneOffset() => 3;
  @override
  Map<String, String> getFavoriteTeamTitles() => {};
  @override
  Future<bool> registerTeamTitles(Map<String, String> titles) async => true;
  @override
  String resolveTeamTitle(String teamOrId, {bool? isArabic}) => teamOrId;
  @override
  List<String> getFavoriteCompetitions() => [];
  @override
  Future<bool> toggleFavoriteCompetition({
    String? compName,
    String? id,
    String? name,
    String? slug,
  }) async => true;
  @override
  bool isFavoriteCompetition({
    String? compName,
    String? id,
    String? name,
    String? slug,
  }) => false;
  @override
  Map<String, String> getFavoriteCompetitionTitles() => {};
  @override
  Future<bool> registerCompetitionTitles(Map<String, String> titles) async => true;
  @override
  String resolveCompetitionTitle(String compOrId) => compOrId;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockTeamsRepository implements TeamsRepository {
  final TeamProfileEntity profile;
  _MockTeamsRepository(this.profile);

  @override
  Future<ApiResult<TeamProfileEntity>> getTeamProfile(
    String teamId, {
    String? teamName,
    String? leagueId,
    required String lang,
  }) async {
    return ApiSuccess(profile);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget createTestApp(Widget child, {Locale locale = const Locale('en')}) {
  final storage = _MockLocalStorageService(lang: locale.languageCode);
  return BlocProvider<FavoritesCubit>(
    create: (_) => FavoritesCubit(storage),
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      theme: ThemeData.dark(),
      home: child,
    ),
  );
}

void main() {
  group('LeagueResolver Title Localization', () {
    test('Translates Africa Cup of Nations Qualification from Arabic to English', () {
      final result = LeagueResolver.resolveTitle(
        'تصفيات كأس أمم أفريقيا',
        isArabic: false,
      );
      expect(result, equals('Africa Cup of Nations Qualification'));
    });

    test('Translates Africa Cup of Nations Qualification from English to Arabic', () {
      final result = LeagueResolver.resolveTitle(
        'Africa Cup of Nations Qualification',
        isArabic: true,
      );
      expect(result, equals('تصفيات كأس أمم أفريقيا'));
    });

    test('Resolves by league ID 943876', () {
      final enResult = LeagueResolver.resolveTitle(
        null,
        isArabic: false,
        id: '943876',
      );
      final arResult = LeagueResolver.resolveTitle(
        null,
        isArabic: true,
        id: '943876',
      );
      expect(enResult, equals('Africa Cup of Nations Qualification'));
      expect(arResult, equals('تصفيات كأس أمم أفريقيا'));
    });
  });

  group('TeamHeaderCard Localization', () {
    testWidgets('Translates Arabic league title to English in English locale', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const profile = TeamProfileEntity(
        teamId: '10255',
        teamName: 'Egypt',
        teamLogo: 'https://imgs.ysscores.com/teams/128/10255.png',
        leagueId: '943876',
        leagueName: 'تصفيات كأس أمم أفريقيا', // Arabic from remote
        country: 'Egypt',
      );

      await tester.pumpWidget(
        createTestApp(
          const Scaffold(
            body: TeamHeaderCard(
              profile: profile,
              fallbackName: 'Egypt',
            ),
          ),
          locale: const Locale('en'),
        ),
      );

      await tester.pumpAndSettle();

      // Should display English localized league name on badge
      expect(find.text('Africa Cup of Nations Qualification'), findsOneWidget);
      expect(find.text('تصفيات كأس أمم أفريقيا'), findsNothing);
    });
  });

  group('Trophies Image Prioritization', () {
    testWidgets('Trophies card prioritizes cup.logo when cupImage has broken CDN /cups/ path', (tester) async {
      tester.view.physicalSize = const Size(800 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const brokenCupUrl = 'https://imgs.ysscores.com/cups/17672635357964.png';
      const validLogoUrl = 'https://imgs.ysscores.com/championship/64/3321747861244.png';

      const profile = TeamProfileEntity(
        teamId: '10255',
        teamName: 'Egypt',
        cups: [
          TeamCupEntity(
            title: 'Africa Cup of Nations',
            count: 7,
            cupImage: brokenCupUrl,
            logo: validLogoUrl,
            years: ['1957', '1959', '1986', '1998', '2006', '2008', '2010'],
          ),
        ],
      );

      final mockRepo = _MockTeamsRepository(profile);
      final mockStorage = _MockLocalStorageService(lang: 'en');
      final teamBloc = TeamBloc(
        repository: mockRepo,
        localStorageService: mockStorage,
        teamId: '10255',
        initialName: 'Egypt',
      );

      await tester.pumpWidget(
        createTestApp(
          BlocProvider<TeamBloc>.value(
            value: teamBloc,
            child: const Scaffold(
              body: TeamView(teamId: '10255', initialName: 'Egypt'),
            ),
          ),
          locale: const Locale('en'),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to Information tab
      final infoTab = find.text('Information');
      expect(infoTab, findsOneWidget);
      await tester.tap(infoTab);
      await tester.pumpAndSettle();

      // AppImage for trophy should have imageUrl equal to validLogoUrl, NOT brokenCupUrl
      final appImages = tester.widgetList<AppImage>(find.byType(AppImage));
      final trophyImages = appImages.where((img) => img.imageUrl == validLogoUrl).toList();
      final brokenImages = appImages.where((img) => img.imageUrl == brokenCupUrl).toList();

      expect(trophyImages.isNotEmpty, isTrue);
      expect(brokenImages.isEmpty, isTrue);
    });
  });

  group('MatchCard Star Removal', () {
    testWidgets('MatchCard does not display any star icon even if match is favorite', (tester) async {
      const match = MatchEntity(
        id: '12345',
        team1: 'Egypt',
        team2: 'Angola',
        time: '22:00',
        date: '2026-09-25',
        status: '22:00',
        isFavorite: true,
      );

      await tester.pumpWidget(
        createTestApp(
          const Scaffold(
            body: MatchCard(match: match, onFavoriteTap: null),
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star_rounded), findsNothing);
      expect(find.byIcon(Icons.star_border_rounded), findsNothing);
    });
  });
}
