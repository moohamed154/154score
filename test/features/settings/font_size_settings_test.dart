import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:score154/core/localization/app_localizations.dart';
import 'package:score154/core/storage/local_storage_service.dart';
import 'package:score154/features/settings/presentation/cubit/settings_cubits.dart';
import 'package:score154/features/settings/presentation/views/font_size_settings_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late LocalStorageService storage;
  late FontSizeCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = LocalStorageServiceImpl(prefs);
    cubit = FontSizeCubit(storage);
  });

  tearDown(() {
    cubit.close();
  });

  group('FontSizeCubit & LocalStorage Tests', () {
    test('initial state defaults to isAuto: true, scale: 1.0', () {
      expect(cubit.state.isAuto, isTrue);
      expect(cubit.state.appFontSizeScale, 1.0);
      expect(cubit.state.newsFontSizeScale, 1.0);
    });

    test('setAuto persists and updates state', () async {
      await cubit.setAuto(false);
      expect(cubit.state.isAuto, isFalse);
      expect(storage.isFontSizeAuto(), isFalse);

      await cubit.setAuto(true);
      expect(cubit.state.isAuto, isTrue);
      expect(storage.isFontSizeAuto(), isTrue);
    });

    test('setAppFontSizeScale automatically sets isAuto: false and persists',
        () async {
      await cubit.setAppFontSizeScale(1.15);
      expect(cubit.state.isAuto, isFalse);
      expect(cubit.state.appFontSizeScale, 1.15);
      expect(storage.getAppFontSizeScale(), 1.15);
      expect(storage.isFontSizeAuto(), isFalse);
    });

    test('setNewsFontSizeScale automatically sets isAuto: false and persists',
        () async {
      await cubit.setNewsFontSizeScale(1.20);
      expect(cubit.state.isAuto, isFalse);
      expect(cubit.state.newsFontSizeScale, 1.20);
      expect(storage.getNewsFontSizeScale(), 1.20);
      expect(storage.isFontSizeAuto(), isFalse);
    });
  });

  group('FontSizeSettingsView Widget Tests', () {
    Widget buildTestWidget({Locale locale = const Locale('ar')}) {
      return MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: BlocProvider<FontSizeCubit>.value(
          value: cubit,
          child: const FontSizeSettingsView(),
        ),
      );
    }

    testWidgets('renders Auto and Manual cards correctly in Arabic',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('حجم الخط'), findsWidgets);
      expect(find.text('تلقائي'), findsOneWidget);
      expect(find.text('يدوي'), findsOneWidget);
      expect(find.text('حجم الخط الافتراضي لهاتفك'), findsOneWidget);
      expect(find.text('اختر حجم الخط المفضل لديك'), findsOneWidget);
    });

    testWidgets('renders in English when locale is en', (tester) async {
      await tester.pumpWidget(buildTestWidget(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Font Size'), findsWidgets);
      expect(find.text('Auto'), findsOneWidget);
      expect(find.text('Manual'), findsOneWidget);
      expect(find.text("Your phone's default font size"), findsOneWidget);
      expect(find.text('Choose your preferred font size'), findsOneWidget);
    });

    testWidgets('tapping Manual reveals sliders and preview text',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(locale: const Locale('en')));
      await tester.pumpAndSettle();

      // Tap on Manual card
      await tester.tap(find.text('Manual'));
      await tester.pumpAndSettle();

      expect(cubit.state.isAuto, isFalse);
      expect(find.text('App font size'), findsOneWidget);
      expect(find.text('News font size'), findsOneWidget);
      expect(find.text('This is a preview text'), findsOneWidget);
      expect(find.byType(Slider), findsNWidgets(2));
    });

    testWidgets('tapping Auto hides sliders and marks Auto as selected',
        (tester) async {
      // Start in manual mode
      await cubit.setAuto(false);

      await tester.pumpWidget(buildTestWidget(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('App font size'), findsOneWidget);

      // Tap on Auto card
      await tester.tap(find.text('Auto'));
      await tester.pumpAndSettle();

      expect(cubit.state.isAuto, isTrue);
    });
  });
}
