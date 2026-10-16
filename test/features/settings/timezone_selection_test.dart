import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:score154/core/localization/app_localizations.dart';
import 'package:score154/core/storage/local_storage_service.dart';
import 'package:score154/features/matches/presentation/bloc/matches_bloc.dart';
import 'package:score154/features/matches/presentation/bloc/matches_state.dart';
import 'package:score154/features/settings/domain/models/utc_offset_info.dart';
import 'package:score154/features/settings/presentation/cubit/settings_cubits.dart';
import 'package:score154/features/settings/presentation/views/timezone_selection_view.dart';

class MockMatchesBloc extends Mock implements MatchesBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UtcOffsetInfo Domain Model', () {
    test('contains all 27 standard UTC offsets from -12 to +14', () {
      final offsets = UtcOffsetInfo.allOffsets.map((e) => e.offset).toList();
      expect(offsets.length, 27);
      expect(offsets.first, -12);
      expect(offsets.last, 14);

      for (int i = -12; i <= 14; i++) {
        expect(offsets.contains(i), isTrue, reason: 'Missing offset UTC $i');
      }
    });

    test('formats positive, negative, and zero offsets correctly', () {
      final plus3 = UtcOffsetInfo.findByOffset(3);
      expect(plus3.formattedOffset, 'UTC +3');

      final minus5 = UtcOffsetInfo.findByOffset(-5);
      expect(minus5.formattedOffset, 'UTC -5');

      final zero = UtcOffsetInfo.findByOffset(0);
      expect(zero.formattedOffset, 'UTC +0');
    });

    test('matches search queries across numeric, Arabic, and English strings',
        () {
      final riyadhOffset = UtcOffsetInfo.findByOffset(3);

      expect(riyadhOffset.matches('3'), isTrue);
      expect(riyadhOffset.matches('+3'), isTrue);
      expect(riyadhOffset.matches('utc+3'), isTrue);
      expect(riyadhOffset.matches('UTC +3'), isTrue);
      expect(riyadhOffset.matches('الرياض'), isTrue);
      expect(riyadhOffset.matches('Riyadh'), isTrue);
      expect(riyadhOffset.matches('Mecca'), isTrue);
      expect(riyadhOffset.matches('مكة'), isTrue);

      final cairoOffset = UtcOffsetInfo.findByOffset(2);
      expect(cairoOffset.matches('القاهرة'), isTrue);
      expect(cairoOffset.matches('Cairo'), isTrue);
      expect(cairoOffset.matches('Tokyo'), isFalse);
    });
  });

  group('LocalStorageService Timezone Offset & Auto Detection', () {
    test('defaults to device UTC offset when not set', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageServiceImpl(prefs);

      final expectedDeviceOffset = DateTime.now().timeZoneOffset.inHours;
      expect(storage.getDeviceTimezoneOffset(), expectedDeviceOffset);
      expect(storage.isTimezoneAuto(), isTrue);
      expect(storage.getTimezoneOffset(), expectedDeviceOffset);
    });

    test('updates offset and disables auto when custom offset set', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageServiceImpl(prefs);

      await storage.setTimezoneOffset(-5);
      expect(storage.isTimezoneAuto(), isFalse);
      expect(storage.getTimezoneOffset(), -5);

      await storage.setTimezoneAuto(true);
      expect(storage.isTimezoneAuto(), isTrue);
      expect(
          storage.getTimezoneOffset(), DateTime.now().timeZoneOffset.inHours);
    });
  });

  group('TimezoneCubit', () {
    test('initializes with device timezone and toggles auto/manual', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageServiceImpl(prefs);
      final cubit = TimezoneCubit(storage);

      final deviceOffset = DateTime.now().timeZoneOffset.inHours;
      expect(cubit.state.offset, deviceOffset);
      expect(cubit.state.isAuto, isTrue);
      expect(cubit.state.deviceOffset, deviceOffset);

      await cubit.setTimezoneOffset(4);
      expect(cubit.state.offset, 4);
      expect(cubit.state.isAuto, isFalse);

      await cubit.setAutoTimezone();
      expect(cubit.state.offset, deviceOffset);
      expect(cubit.state.isAuto, isTrue);

      await cubit.close();
    });
  });

  group('TimezoneSelectionView Widget Tests', () {
    late LocalStorageService storage;
    late TimezoneCubit timezoneCubit;
    late MockMatchesBloc mockMatchesBloc;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storage = LocalStorageServiceImpl(prefs);
      timezoneCubit = TimezoneCubit(storage);
      mockMatchesBloc = MockMatchesBloc();
      when(() => mockMatchesBloc.state).thenReturn(
        MatchesState(selectedDate: DateTime(2026, 9, 24)),
      );
      when(() => mockMatchesBloc.stream)
          .thenAnswer((_) => const Stream.empty());
    });

    tearDown(() async {
      await timezoneCubit.close();
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        // ignore: prefer_const_literals_to_create_immutables
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: MultiBlocProvider(
          providers: [
            BlocProvider<TimezoneCubit>.value(value: timezoneCubit),
            BlocProvider<MatchesBloc>.value(value: mockMatchesBloc),
          ],
          child: const TimezoneSelectionView(),
        ),
      );
    }

    testWidgets('renders search field, auto device tile, and offset list',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('تلقائي (توقيت الجهاز)'), findsWidgets);
      expect(find.text('جميع المناطق وفروق التوقيت'), findsOneWidget);
      expect(find.text('UTC +3'), findsWidgets);
    });

    testWidgets('filters timezones when user types into search',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'القاهرة');
      await tester.pumpAndSettle();

      expect(find.text('توقيت القاهرة والقدس وطرابلس وعمان'), findsOneWidget);
      expect(find.text('توقيت اليابان وكوريا (طوكيو، سيول)'), findsNothing);
    });

    testWidgets('selecting an offset updates cubit', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Search for Tokyo / Japan (UTC +9)
      await tester.enterText(find.byType(TextField), 'طوكيو');
      await tester.pumpAndSettle();

      final tokyoTile = find.text('توقيت اليابان وكوريا (طوكيو، سيول)');
      expect(tokyoTile, findsOneWidget);

      await tester.tap(tokyoTile);
      await tester.pumpAndSettle();

      expect(timezoneCubit.state.offset, 9);
      expect(timezoneCubit.state.isAuto, isFalse);
    });
  });
}
