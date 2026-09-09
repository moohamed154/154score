import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ysscores/core/constants/api_endpoints.dart';
import 'package:ysscores/core/localization/app_localizations.dart';
import 'package:ysscores/core/network/api_client.dart';
import 'package:ysscores/core/storage/local_storage_service.dart';
import 'package:ysscores/core/theme/app_theme.dart';
import 'package:ysscores/core/websocket/websocket_service.dart';
import 'package:ysscores/features/match_details/data/datasources/match_details_remote_datasource.dart';
import 'package:ysscores/features/match_details/domain/entities/match_details_entity.dart';
import 'package:ysscores/features/match_details/domain/repositories/match_details_repository.dart';
import 'package:ysscores/features/match_details/presentation/bloc/match_details_bloc.dart';
import 'package:ysscores/features/match_details/presentation/bloc/match_details_state.dart';
import 'package:ysscores/features/match_details/presentation/widgets/lineup/lineup_empty_state_widget.dart';
import 'package:ysscores/features/match_details/presentation/widgets/lineup/lineup_squad_list_widget.dart';
import 'package:ysscores/features/match_details/presentation/widgets/lineup/lineup_tab_view.dart';
import 'package:ysscores/features/match_details/presentation/widgets/lineup/match_pitch_widget.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockMatchDetailsRepository extends Mock
    implements MatchDetailsRepository {}

class MockWebSocketService extends Mock implements WebSocketService {}

class MockLocalStorageService extends Mock implements LocalStorageService {}

Widget buildTestApp({
  required Widget child,
  Locale locale = const Locale('ar'),
  double width = 390,
  double height = 844,
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    theme: AppTheme.darkTheme,
    home: MediaQuery(
      data: MediaQueryData(size: Size(width, height)),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(const Locale('ar'));
  });

  group('MatchDetailsRemoteDataSource — Lineup Parsing Tests', () {
    late MockApiClient mockClient;
    late MatchDetailsRemoteDataSourceImpl dataSource;

    setUp(() {
      mockClient = MockApiClient();
      dataSource = MatchDetailsRemoteDataSourceImpl(mockClient);
    });

    test('1. Parses confirmed lineup with formations, coaches, starters, subs, and injuries', () async {
      when(
        () => mockClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => {
          'success': true,
          'data': {
            'match_id': '5868020',
            'lineups_available': true,
            'formation_type': 'confirmed',
            'home': {
              'team_id': '101',
              'team_name': 'فالنسيا',
              'team_logo': 'https://imgs.ysscores.com/teams/101.png',
              'formation': '5-3-2',
              'coach': {
                'coach_id': '819',
                'name': 'كارلوس كوربيران',
                'photo': 'https://imgs.ysscores.com/coach/819.png',
              },
              'starting_xi': [
                {
                  'player_id': '1',
                  'name': 'ديميتريفسكي',
                  'number': 1,
                  'position': 'حارس المرمى',
                  'position_code': 'G',
                  'formation_position': 1,
                  'rating': '6.8',
                  'is_captain': false,
                  'is_starter': true,
                },
                {
                  'player_id': '2',
                  'name': 'فاسكيز',
                  'number': 21,
                  'position': 'الظهير الأيسر',
                  'position_code': 'D',
                  'formation_position': 1,
                  'rating': '7.1',
                  'is_captain': true,
                  'is_starter': true,
                },
              ],
              'substitutes': [
                {
                  'player_id': '10',
                  'name': 'خاومي دومينيك',
                  'number': 13,
                  'position': 'حارس مرمى',
                  'position_code': 'SUB',
                  'is_starter': false,
                  'is_substitute': true,
                },
              ],
              'injuries': [
                {
                  'player_id': '99',
                  'name': 'غايا',
                  'number': 14,
                  'position': 'مدافع',
                  'absence_reason': 'مصاب',
                },
              ],
            },
            'away': {
              'team_id': '102',
              'team_name': 'ريال بيتيس',
              'formation': '4-2-3-1',
              'starting_xi': [
                {
                  'player_id': '20',
                  'name': 'سيلفا',
                  'number': 1,
                  'position': 'حارس المرمى',
                  'position_code': 'G',
                  'formation_position': 1,
                  'is_starter': true,
                },
              ],
              'substitutes': [],
              'injuries': [],
            },
          },
        },
      );

      final result = await dataSource.getLineups('5868020', lang: 'ar');

      expect(result, isNotNull);
      expect(result!.matchId, '5868020');
      expect(result.lineupsAvailable, isTrue);
      expect(result.isConfirmed, isTrue);
      expect(result.hasLineups, isTrue);

      // Home verification
      final home = result.home!;
      expect(home.teamName, 'فالنسيا');
      expect(home.formation, '5-3-2');
      expect(home.coach?.name, 'كارلوس كوربيران');
      expect(home.startingXi.length, 2);
      expect(home.startingXi[0].name, 'ديميتريفسكي');
      expect(home.startingXi[0].isGoalkeeper, isTrue);
      expect(home.startingXi[1].isCaptain, isTrue);
      expect(home.substitutes.length, 1);
      expect(home.substitutes[0].isSubstitute, isTrue);
      expect(home.injuries.length, 1);
      expect(home.injuries[0].absenceReason, 'مصاب');

      // Away verification
      final away = result.away!;
      expect(away.teamName, 'ريال بيتيس');
      expect(away.formation, '4-2-3-1');
      expect(away.startingXi.length, 1);
    });

    test('2. Handles lineups_available == false gracefully', () async {
      when(
        () => mockClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => {
          'success': true,
          'data': {
            'match_id': '999',
            'lineups_available': false,
            'home': null,
            'away': null,
          },
        },
      );

      final result = await dataSource.getLineups('999', lang: 'ar');

      expect(result, isNotNull);
      expect(result!.lineupsAvailable, isFalse);
      expect(result.hasLineups, isFalse);
    });

    test('3. Returns null on network exception without throwing', () async {
      when(
        () => mockClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(Exception('Server unreachable'));

      final result = await dataSource.getLineups('999', lang: 'ar');
      expect(result, isNull);
    });

    test('4. Strips "أخبار نادي" and "اخبار نادي" prefixes from team names cleanly', () async {
      when(
        () => mockClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => {
          'success': true,
          'data': {
            'match_id': '5868020',
            'lineups_available': true,
            'home': {
              'team_name': 'أخبار نادي ريال مدريد',
              'formation': '4-3-3',
              'starting_xi': [],
            },
            'away': {
              'team_name': 'اخبار نادي ريال بيتيس',
              'formation': '4-2-3-1',
              'starting_xi': [],
            },
          },
        },
      );

      final result = await dataSource.getLineups('5868020', lang: 'ar');

      expect(result?.home?.teamName, 'ريال مدريد');
      expect(result?.away?.teamName, 'ريال بيتيس');
      expect(result?.home?.displayName, 'ريال مدريد');
      expect(result?.away?.displayName, 'ريال بيتيس');
    });

    test('5. Strips "News" suffix in English team names while preserving names like "Newcastle"', () async {
      when(
        () => mockClient.get(
          any(),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => {
          'success': true,
          'data': {
            'match_id': '5868020',
            'lineups_available': true,
            'home': {
              'team_name': 'Real Madrid News',
              'formation': '4-3-3',
              'starting_xi': [],
            },
            'away': {
              'team_name': 'Newcastle United News',
              'formation': '4-2-3-1',
              'starting_xi': [],
            },
          },
        },
      );

      final result = await dataSource.getLineups('5868020', lang: 'en');

      expect(result?.home?.teamName, 'Real Madrid');
      expect(result?.away?.teamName, 'Newcastle United');
      expect(result?.home?.displayName, 'Real Madrid');
      expect(result?.away?.displayName, 'Newcastle United');
    });

    test('6. Auto-heals missing striker (\'S\') when API returns 10 players, resulting in 11 players in tactical order', () async {
      when(
        () => mockClient.get(
          ApiEndpoints.matchLineups('5795441'),
          queryParameters: {'lang': 'ar'},
        ),
      ).thenAnswer(
        (_) async => {
          'success': true,
          'data': {
            'match_id': '5795441',
            'lineups_available': true,
            'formation_type': 'confirmed',
            'home': {
              'team_id': '9902',
              'team_name': 'إبسويتش تاون',
              'formation': '4-2-3-1',
              'starting_xi': [
                {'player_id': '1', 'name': 'شيربن', 'position_code': 'G'},
                {'player_id': '2', 'name': 'ديفيس', 'position_code': 'D'},
                {'player_id': '3', 'name': 'جريفز', 'position_code': 'D'},
                {'player_id': '4', 'name': 'ديوب', 'position_code': 'D'},
                {'player_id': '5', 'name': 'أوشي', 'position_code': 'D'},
                {'player_id': '6', 'name': 'لوكيك', 'position_code': 'M'},
                {'player_id': '7', 'name': 'بالاسيوس', 'position_code': 'M'},
                {'player_id': '8', 'name': 'ماييدا', 'position_code': 'F'},
                {'player_id': '9', 'name': 'إنسيسو', 'position_code': 'F'},
                {'player_id': '10', 'name': 'الفتاح', 'position_code': 'F'},
              ],
              'substitutes': [],
              'injuries': [],
            },
            'away': {
              'team_id': '8650',
              'team_name': 'ليفربول',
              'formation': '4-2-3-1',
              'starting_xi': [
                {'player_id': '101', 'name': 'بيكر', 'position_code': 'G'},
                {'player_id': '102', 'name': 'كيركيز', 'position_code': 'D'},
                {'player_id': '103', 'name': 'فان دايك', 'position_code': 'D'},
                {'player_id': '104', 'name': 'جاكيه', 'position_code': 'D'},
                {'player_id': '105', 'name': 'أراوخو', 'position_code': 'D'},
                {'player_id': '106', 'name': 'سوبوسلاي', 'position_code': 'M'},
                {'player_id': '107', 'name': 'أليستير', 'position_code': 'M'},
                {'player_id': '108', 'name': 'مونيوز', 'position_code': 'F'},
                {'player_id': '109', 'name': 'جاكبو', 'position_code': 'F'},
                {'player_id': '110', 'name': 'فيرتز', 'position_code': 'F'},
              ],
              'substitutes': [],
              'injuries': [],
            },
          },
        },
      );

      when(
        () => mockClient.get(
          'https://www.ysscores.com/ar/match_lineup?match_code=5795441',
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => {
          'info': {'home_team': 9902, 'away_team': 8650},
          'lineup': {
            '9902': {
              'S': {
                '1': {
                  'player': {
                    'row_id': 1320949,
                    'title': 'إيمرسون',
                    'player_number': 0,
                    'position': 'قلب الهجوم',
                  },
                  'formation_position': 1,
                  'rating': '6.3',
                },
              },
            },
            '8650': {
              'S': {
                '1': {
                  'player': {
                    'row_id': 690107,
                    'title': 'إيساك',
                    'player_number': 9,
                    'position': 'قلب الهجوم',
                  },
                  'formation_position': 1,
                  'rating': '8.1',
                },
              },
            },
          },
        },
      );

      final result = await dataSource.getLineups('5795441', lang: 'ar');

      expect(result, isNotNull);
      expect(result!.home!.startingXi.length, 11);
      expect(result.away!.startingXi.length, 11);

      // Verify the healed strikers exist and are in the starting XI
      final homeStriker = result.home!.startingXi.firstWhere(
        (p) => p.name == 'إيمرسون',
      );
      expect(homeStriker.positionCode, 'S');
      expect(homeStriker.number, 0);

      final awayStriker = result.away!.startingXi.firstWhere(
        (p) => p.name == 'إيساك',
      );
      expect(awayStriker.positionCode, 'S');
      expect(awayStriker.number, 9);
      expect(awayStriker.rating, '8.1');

      // Verify tactically sorted (Striker is at index 10)
      expect(result.home!.startingXi.last.name, 'إيمرسون');
      expect(result.away!.startingXi.last.name, 'إيساك');
    });
  });

  group('Match Lineup UI & Responsive Widget Tests', () {
    late MockMatchDetailsRepository mockRepo;
    late MockWebSocketService mockWs;
    late MockLocalStorageService mockStorage;

    const sampleMatchId = '5868020';

    const sampleLineup = MatchLineupEntity(
      matchId: sampleMatchId,
      lineupsAvailable: true,
      formationType: 'confirmed',
      home: TeamLineupEntity(
        teamId: '1',
        teamName: 'ريال مدريد',
        teamLogo: 'https://imgs.ysscores.com/teams/real.png',
        formation: '4-3-3',
        coach: LineupCoachEntity(coachId: '9', name: 'كارلو أنشيلوتي'),
        startingXi: [
          LineupPlayerEntity(
            playerId: '1',
            name: 'كورتوا',
            number: 1,
            position: 'حارس المرمى',
            positionCode: 'G',
            formationPosition: 1,
            rating: '7.4',
            isCaptain: false,
          ),
          LineupPlayerEntity(
            playerId: '2',
            name: 'كارفخال',
            number: 2,
            position: 'ظهير أيمن',
            positionCode: 'D',
            formationPosition: 1,
            isCaptain: true,
          ),
          LineupPlayerEntity(
            playerId: '3',
            name: 'روديغر',
            number: 22,
            position: 'قلب دفاع',
            positionCode: 'D',
            formationPosition: 2,
          ),
          LineupPlayerEntity(
            playerId: '4',
            name: 'ميليتاو',
            number: 3,
            position: 'قلب دفاع',
            positionCode: 'D',
            formationPosition: 3,
          ),
          LineupPlayerEntity(
            playerId: '5',
            name: 'ميندي',
            number: 23,
            position: 'ظهير أيسر',
            positionCode: 'D',
            formationPosition: 4,
          ),
          LineupPlayerEntity(
            playerId: '6',
            name: 'فالفيردي',
            number: 8,
            position: 'وسط',
            positionCode: 'M',
            formationPosition: 1,
          ),
          LineupPlayerEntity(
            playerId: '7',
            name: 'تشواميني',
            number: 14,
            position: 'وسط مدافع',
            positionCode: 'M',
            formationPosition: 2,
          ),
          LineupPlayerEntity(
            playerId: '8',
            name: 'بيلينغهام',
            number: 5,
            position: 'وسط مهاجم',
            positionCode: 'M',
            formationPosition: 3,
            rating: '8.2',
          ),
          LineupPlayerEntity(
            playerId: '9',
            name: 'رودريغو',
            number: 11,
            position: 'جناح أيمن',
            positionCode: 'F',
            formationPosition: 1,
          ),
          LineupPlayerEntity(
            playerId: '10',
            name: 'مبابي',
            number: 9,
            position: 'مهاجم',
            positionCode: 'F',
            formationPosition: 2,
            rating: '8.5',
          ),
          LineupPlayerEntity(
            playerId: '11',
            name: 'فينيسيوس',
            number: 7,
            position: 'جناح أيسر',
            positionCode: 'F',
            formationPosition: 3,
            rating: '8.7',
          ),
        ],
        substitutes: [
          LineupPlayerEntity(
            playerId: '12',
            name: 'مودريتش',
            number: 10,
            position: 'وسط',
            positionCode: 'SUB',
            isStarter: false,
            isSubstitute: true,
          ),
        ],
        injuries: [
          LineupInjuryEntity(
            playerId: '99',
            name: 'ألابا',
            number: 4,
            position: 'دفاع',
            absenceReason: 'رباط صليبي',
          ),
        ],
      ),
      away: TeamLineupEntity(
        teamId: '2',
        teamName: 'برشلونة',
        teamLogo: 'https://imgs.ysscores.com/teams/barca.png',
        formation: '4-3-3',
        coach: LineupCoachEntity(coachId: '8', name: 'هانز فليك'),
        startingXi: [
          LineupPlayerEntity(
            playerId: '21',
            name: 'تير شتيغن',
            number: 1,
            position: 'حارس المرمى',
            positionCode: 'G',
            formationPosition: 1,
          ),
          LineupPlayerEntity(
            playerId: '22',
            name: 'كوندي',
            number: 23,
            position: 'ظهير أيمن',
            positionCode: 'D',
            formationPosition: 1,
          ),
          LineupPlayerEntity(
            playerId: '23',
            name: 'كوبارسي',
            number: 2,
            position: 'قلب دفاع',
            positionCode: 'D',
            formationPosition: 2,
          ),
          LineupPlayerEntity(
            playerId: '24',
            name: 'إينيغو',
            number: 5,
            position: 'قلب دفاع',
            positionCode: 'D',
            formationPosition: 3,
          ),
          LineupPlayerEntity(
            playerId: '25',
            name: 'بالدي',
            number: 3,
            position: 'ظهير أيسر',
            positionCode: 'D',
            formationPosition: 4,
          ),
          LineupPlayerEntity(
            playerId: '26',
            name: 'كاسادو',
            number: 17,
            position: 'وسط مدافع',
            positionCode: 'M',
            formationPosition: 1,
          ),
          LineupPlayerEntity(
            playerId: '27',
            name: 'بيدري',
            number: 8,
            position: 'وسط',
            positionCode: 'M',
            formationPosition: 2,
            rating: '7.9',
          ),
          LineupPlayerEntity(
            playerId: '28',
            name: 'أولمو',
            number: 20,
            position: 'وسط مهاجم',
            positionCode: 'M',
            formationPosition: 3,
          ),
          LineupPlayerEntity(
            playerId: '29',
            name: 'يامال',
            number: 19,
            position: 'جناح أيمن',
            positionCode: 'F',
            formationPosition: 1,
            rating: '8.6',
          ),
          LineupPlayerEntity(
            playerId: '30',
            name: 'ليفاندوفسكي',
            number: 9,
            position: 'مهاجم',
            positionCode: 'F',
            formationPosition: 2,
            rating: '8.1',
          ),
          LineupPlayerEntity(
            playerId: '31',
            name: 'رافينيا',
            number: 11,
            position: 'جناح أيسر',
            positionCode: 'F',
            formationPosition: 3,
            rating: '8.4',
            isCaptain: true,
          ),
        ],
        substitutes: [],
        injuries: [],
      ),
    );

    setUp(() {
      mockRepo = MockMatchDetailsRepository();
      mockWs = MockWebSocketService();
      mockStorage = MockLocalStorageService();

      when(() => mockWs.matchUpdatesStream(any()))
          .thenAnswer((_) => const Stream.empty());
      when(() => mockWs.updatesStream).thenAnswer((_) => const Stream.empty());
      when(() => mockWs.joinMatchRoom(any())).thenReturn(null);
      when(() => mockWs.leaveMatchRoom(any())).thenReturn(null);

      when(() => mockStorage.getLanguage()).thenReturn('ar');
      when(() => mockStorage.getTimezoneOffset()).thenReturn(3);
    });

    testWidgets(
      '1. Renders tactical pitch board with both formations when lineups are available',
      (tester) async {
        final bloc = MatchDetailsBloc(
          repository: mockRepo,
          webSocketService: mockWs,
          localStorageService: mockStorage,
          matchId: sampleMatchId,
        );

        // Seed state with lineup loaded
        bloc.emit(
          const MatchDetailsState(
            matchId: sampleMatchId,
            status: MatchDetailsStatus.success,
            lineup: sampleLineup,
          ),
        );

        await tester.pumpWidget(
          buildTestApp(
            child: BlocProvider.value(
              value: bloc,
              child: const LineupTabView(matchId: sampleMatchId),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify pitch board is rendered
        expect(find.byType(MatchPitchWidget), findsOneWidget);
        expect(find.text('تشكيلة مؤكدة'), findsOneWidget);
        expect(find.text('ريال مدريد'), findsWidgets);
        expect(find.text('برشلونة'), findsWidgets);

        // Verify player node exists for home team on pitch
        expect(find.text('مبابي'), findsWidgets);

        // Toggle to away team (Barcelona)
        await tester.tap(find.text('برشلونة').first);
        await tester.pumpAndSettle();

        // Verify player node exists for away team on pitch
        expect(find.text('يامال'), findsWidgets);
      },
    );

    testWidgets('2. Switches to Squad List view when List toggle is tapped', (
      tester,
    ) async {
      final bloc = MatchDetailsBloc(
        repository: mockRepo,
        webSocketService: mockWs,
        localStorageService: mockStorage,
        matchId: sampleMatchId,
      );

      bloc.emit(
        const MatchDetailsState(
          matchId: sampleMatchId,
          status: MatchDetailsStatus.success,
          lineup: sampleLineup,
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          child: BlocProvider.value(
            value: bloc,
            child: const LineupTabView(matchId: sampleMatchId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap 'القائمة' (List) switcher
      final listBtn = find.text('القائمة');
      expect(listBtn, findsOneWidget);
      await tester.tap(listBtn);
      await tester.pumpAndSettle();

      // Verify list view elements
      expect(find.byType(LineupSquadListWidget), findsOneWidget);
      expect(find.text('التشكيلة الأساسية'), findsOneWidget);
      expect(find.text('دكة البدلاء'), findsOneWidget);
      expect(find.text('كارلو أنشيلوتي'), findsOneWidget);
      expect(find.text('الغيابات والإصابات'), findsOneWidget);
    });

    testWidgets('3. Renders empty state when lineups are not available', (
      tester,
    ) async {
      final bloc = MatchDetailsBloc(
        repository: mockRepo,
        webSocketService: mockWs,
        localStorageService: mockStorage,
        matchId: sampleMatchId,
      );

      bloc.emit(
        const MatchDetailsState(
          matchId: sampleMatchId,
          status: MatchDetailsStatus.success,
          lineup: MatchLineupEntity(
            matchId: sampleMatchId,
            lineupsAvailable: false,
            home: null,
            away: null,
          ),
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          child: BlocProvider.value(
            value: bloc,
            child: const LineupTabView(matchId: sampleMatchId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(LineupEmptyStateWidget), findsOneWidget);
      expect(find.text('لم يتم الإعلان عن التشكيلة بعد'), findsOneWidget);
      expect(find.text('تحديث التشكيلة'), findsOneWidget);
    });

    testWidgets('4. Zero-overflow audit on compact 320px screen', (
      tester,
    ) async {
      final bloc = MatchDetailsBloc(
        repository: mockRepo,
        webSocketService: mockWs,
        localStorageService: mockStorage,
        matchId: sampleMatchId,
      );

      bloc.emit(
        const MatchDetailsState(
          matchId: sampleMatchId,
          status: MatchDetailsStatus.success,
          lineup: sampleLineup,
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          width: 320,
          height: 568,
          child: BlocProvider.value(
            value: bloc,
            child: const LineupTabView(matchId: sampleMatchId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MatchPitchWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('5. Localization audit in English mode', (tester) async {
      final bloc = MatchDetailsBloc(
        repository: mockRepo,
        webSocketService: mockWs,
        localStorageService: mockStorage,
        matchId: sampleMatchId,
      );

      bloc.emit(
        const MatchDetailsState(
          matchId: sampleMatchId,
          status: MatchDetailsStatus.success,
          lineup: sampleLineup,
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          locale: const Locale('en'),
          child: BlocProvider.value(
            value: bloc,
            child: const LineupTabView(matchId: sampleMatchId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Confirmed Lineup'), findsOneWidget);
      expect(find.text('Pitch'), findsOneWidget);
      expect(find.text('List'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('6. Sanitizes team names with "أخبار نادي" in UI and omits team logos from pitch badge and tabs', (
      tester,
    ) async {
      final bloc = MatchDetailsBloc(
        repository: mockRepo,
        webSocketService: mockWs,
        localStorageService: mockStorage,
        matchId: sampleMatchId,
      );

      final uncleanedLineup = MatchLineupEntity(
        matchId: sampleMatchId,
        lineupsAvailable: true,
        formationType: 'confirmed',
        home: TeamLineupEntity(
          teamId: '1',
          teamName: 'أخبار نادي ريال مدريد',
          teamLogo: 'https://imgs.ysscores.com/teams/real.png',
          formation: '4-3-3',
          startingXi: sampleLineup.home!.startingXi,
        ),
        away: TeamLineupEntity(
          teamId: '2',
          teamName: 'اخبار نادي ريال بيتيس',
          teamLogo: 'https://imgs.ysscores.com/teams/betis.png',
          formation: '4-2-3-1',
          startingXi: sampleLineup.away!.startingXi,
        ),
      );

      bloc.emit(
        MatchDetailsState(
          matchId: sampleMatchId,
          status: MatchDetailsStatus.success,
          lineup: uncleanedLineup,
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          child: BlocProvider.value(
            value: bloc,
            child: const LineupTabView(matchId: sampleMatchId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Pitch board should show 'ريال مدريد' and 'ريال بيتيس' without 'أخبار نادي'
      expect(find.text('ريال مدريد'), findsWidgets);
      expect(find.text('ريال بيتيس'), findsWidgets);
      expect(find.textContaining('أخبار نادي'), findsNothing);
      expect(find.textContaining('اخبار نادي'), findsNothing);

      // Switch to squad list view
      await tester.tap(find.text('القائمة'));
      await tester.pumpAndSettle();

      // Squad list tabs should also show 'ريال مدريد' and 'ريال بيتيس' without 'أخبار نادي'
      expect(find.text('ريال مدريد'), findsWidgets);
      expect(find.text('ريال بيتيس'), findsWidgets);
      expect(find.textContaining('أخبار نادي'), findsNothing);
      expect(find.textContaining('اخبار نادي'), findsNothing);
    });

    testWidgets('7. Uses formation "4-2-3-1" from response to partition tactical lines into separate 4, 2, 3 rows', (
      tester,
    ) async {
      final bloc = MatchDetailsBloc(
        repository: mockRepo,
        webSocketService: mockWs,
        localStorageService: mockStorage,
        matchId: sampleMatchId,
      );

      const realBetisLineup = MatchLineupEntity(
        matchId: sampleMatchId,
        lineupsAvailable: true,
        formationType: 'confirmed',
        home: TeamLineupEntity(
          teamId: '8603',
          teamName: 'ريال بيتيس',
          formation: '4-2-3-1',
          startingXi: [
            LineupPlayerEntity(playerId: '1', name: 'فاييس', number: 1, positionCode: 'G', formationPosition: 1),
            LineupPlayerEntity(playerId: '11', name: 'غارسيا', number: 11, positionCode: 'D', formationPosition: 1),
            LineupPlayerEntity(playerId: '4', name: 'ناتان', number: 4, positionCode: 'D', formationPosition: 2),
            LineupPlayerEntity(playerId: '3', name: 'يورينتي', number: 3, positionCode: 'D', formationPosition: 3),
            LineupPlayerEntity(playerId: '2', name: 'بيليرين', number: 2, positionCode: 'D', formationPosition: 4),
            LineupPlayerEntity(playerId: '21', name: 'روكا', number: 21, positionCode: 'M', formationPosition: 1),
            LineupPlayerEntity(playerId: '6', name: 'بيرنال', number: 6, positionCode: 'M', formationPosition: 2),
            LineupPlayerEntity(playerId: '8', name: 'فورنالس', number: 8, positionCode: 'F', formationPosition: 1),
            LineupPlayerEntity(playerId: '22', name: 'إيسكو', number: 22, positionCode: 'F', formationPosition: 2),
            LineupPlayerEntity(playerId: '7', name: 'أنتوني', number: 7, positionCode: 'F', formationPosition: 3),
            LineupPlayerEntity(playerId: '9', name: 'هيرنانديز', number: 9, positionCode: 'S', formationPosition: 1),
          ],
        ),
        away: TeamLineupEntity(
          teamId: '8633',
          teamName: 'ريال مدريد',
          formation: '4-2-3-1',
          startingXi: [
            LineupPlayerEntity(playerId: '1', name: 'كورتوا', number: 1, positionCode: 'G', formationPosition: 1),
            LineupPlayerEntity(playerId: '17', name: 'كوكورييا', number: 17, positionCode: 'D', formationPosition: 1),
            LineupPlayerEntity(playerId: '4', name: 'هاوسن', number: 4, positionCode: 'D', formationPosition: 2),
            LineupPlayerEntity(playerId: '16', name: 'كوناتي', number: 16, positionCode: 'D', formationPosition: 3),
            LineupPlayerEntity(playerId: '24', name: 'دومفريس', number: 24, positionCode: 'D', formationPosition: 4),
            LineupPlayerEntity(playerId: '6', name: 'كامافينجا', number: 6, positionCode: 'M', formationPosition: 1),
            LineupPlayerEntity(playerId: '8', name: 'فالفيردي', number: 8, positionCode: 'M', formationPosition: 2),
            LineupPlayerEntity(playerId: '7', name: 'جونيور', number: 7, positionCode: 'F', formationPosition: 1),
            LineupPlayerEntity(playerId: '5', name: 'بيلينغهام', number: 5, positionCode: 'F', formationPosition: 2),
            LineupPlayerEntity(playerId: '15', name: 'غولر', number: 15, positionCode: 'F', formationPosition: 3),
            LineupPlayerEntity(playerId: '10', name: 'مبابي', number: 10, positionCode: 'S', formationPosition: 1),
          ],
        ),
      );

      bloc.emit(
        const MatchDetailsState(
          matchId: sampleMatchId,
          status: MatchDetailsStatus.success,
          lineup: realBetisLineup,
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          child: BlocProvider.value(
            value: bloc,
            child: const LineupTabView(matchId: sampleMatchId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Pitch board is present
      expect(find.byType(MatchPitchWidget), findsOneWidget);

      // Verify Home team (Real Betis) players across tactical lines are rendered
      expect(find.text('فاييس'), findsWidgets);
      expect(find.text('غارسيا'), findsWidgets);
      expect(find.text('بيليرين'), findsWidgets);
      expect(find.text('روكا'), findsWidgets);
      expect(find.text('بيرنال'), findsWidgets);
      expect(find.text('فورنالس'), findsWidgets);
      expect(find.text('إيسكو'), findsWidgets);
      expect(find.text('أنتوني'), findsWidgets);
      expect(find.text('هيرنانديز'), findsWidgets);

      // Toggle to Away team (Real Madrid)
      await tester.tap(find.text('ريال مدريد').first);
      await tester.pumpAndSettle();

      // Verify Away team (Real Madrid) players are now rendered on pitch
      expect(find.text('كورتوا'), findsWidgets);
      expect(find.text('مبابي'), findsWidgets);
    });

    testWidgets('8. Verifies Arabic font (Cairo) is applied to pitch team badges and player tags in Arabic mode', (
      tester,
    ) async {
      final bloc = MatchDetailsBloc(
        repository: mockRepo,
        webSocketService: mockWs,
        localStorageService: mockStorage,
        matchId: sampleMatchId,
      );

      bloc.emit(
        const MatchDetailsState(
          matchId: sampleMatchId,
          status: MatchDetailsStatus.success,
          lineup: sampleLineup,
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          locale: const Locale('ar'),
          child: BlocProvider.value(
            value: bloc,
            child: const LineupTabView(matchId: sampleMatchId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find team badge text 'ريال مدريد'
      final teamTextWidget = tester.widget<Text>(find.text('ريال مدريد').first);
      expect(teamTextWidget.style?.fontFamily, contains('Cairo'));

      // Find player tag text 'كورتوا'
      final playerTextWidget = tester.widget<Text>(find.text('كورتوا').first);
      expect(playerTextWidget.style?.fontFamily, contains('Cairo'));
    });
  });
}
