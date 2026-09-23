import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:score154/core/di/injection_container.dart';
import 'package:score154/core/localization/app_localizations.dart';
import 'package:score154/core/network/network_info.dart';
import 'package:score154/features/home/presentation/cubit/home_cubit.dart';
import 'package:score154/features/matches/presentation/bloc/matches_bloc.dart';
import 'package:score154/features/matches/presentation/bloc/matches_event.dart';
import 'package:score154/features/matches/presentation/bloc/matches_state.dart';
import 'package:score154/core/constants/app_colors.dart';
import 'package:score154/features/splash/presentation/views/splash_view.dart';

class MockHomeCubit extends Mock implements HomeCubit {}
class MockMatchesBloc extends Mock implements MatchesBloc {}
class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late MockNetworkInfo mockNetworkInfo;

  setUpAll(() {
    registerFallbackValue(LoadMatchesEvent(date: DateTime.now()));
  });

  setUp(() {
    mockNetworkInfo = MockNetworkInfo();
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
    when(() => mockNetworkInfo.onConnectivityChanged)
        .thenAnswer((_) => const Stream<bool>.empty());

    if (sl.isRegistered<NetworkInfo>()) {
      sl.unregister<NetworkInfo>();
    }
    sl.registerLazySingleton<NetworkInfo>(() => mockNetworkInfo);
  });

  tearDown(() {
    if (sl.isRegistered<NetworkInfo>()) {
      sl.unregister<NetworkInfo>();
    }
  });

  group('SplashView Widget & Real Loading Tests', () {
    testWidgets('renders all brand, logo, title, and real progress bar cleanly (no v1.0.0)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: SplashView(),
        ),
      );
      await tester.pump();

      // Verify immediate presence of scaffold, icon, 154, SCORE
      expect(find.byType(SplashView), findsOneWidget);
      expect(find.byIcon(Icons.sports_soccer_rounded), findsOneWidget);
      expect(find.text('154'), findsOneWidget);
      expect(find.text('SCORE'), findsOneWidget);

      // Verify v1.0.0 is completely deleted
      expect(find.textContaining('v1.0'), findsNothing);

      // Advance initial layout & progress animation
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(SplashView), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 800));
    });

    testWidgets('tap to skip navigates to / route via GoRouter', (tester) async {
      String currentPath = '/splash';

      final testRouter = GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(
            path: '/splash',
            builder: (context, state) => const SplashView(),
          ),
          GoRoute(
            path: '/',
            builder: (context, state) {
              currentPath = '/';
              return const Scaffold(body: Text('Home Screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(SplashView), findsOneWidget);

      // Tap on screen to skip
      await tester.tap(find.byType(SplashView));
      await tester.pumpAndSettle();

      expect(currentPath, equals('/'));
      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('auto-navigates to / when real loading completes for HomeCubit and MatchesBloc', (tester) async {
      String currentPath = '/splash';
      final mockHome = MockHomeCubit();
      final mockMatches = MockMatchesBloc();

      final homeController = StreamController<HomeState>.broadcast();
      final matchesController = StreamController<MatchesState>.broadcast();

      when(() => mockHome.state).thenReturn(const HomeState(status: HomeStatus.initial));
      when(() => mockHome.loadHomeData()).thenAnswer((_) async {});
      when(() => mockHome.stream).thenAnswer((_) => homeController.stream);

      final initialMatchesState = MatchesState(
        selectedDate: DateTime(2026, 9, 20),
        status: MatchesStatus.initial,
      );
      when(() => mockMatches.state).thenReturn(initialMatchesState);
      when(() => mockMatches.stream).thenAnswer((_) => matchesController.stream);

      final testRouter = GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(
            path: '/splash',
            builder: (context, state) => const SplashView(),
          ),
          GoRoute(
            path: '/',
            builder: (context, state) {
              currentPath = '/';
              return const Scaffold(body: Text('Home Screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<HomeCubit>.value(value: mockHome),
            BlocProvider<MatchesBloc>.value(value: mockMatches),
          ],
          child: MaterialApp.router(
            routerConfig: testRouter,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SplashView), findsOneWidget);

      // First frame post-callback dispatches real load
      await tester.pump(const Duration(milliseconds: 100));

      verifyNever(() => mockHome.loadHomeData());
      verify(() => mockMatches.add(any(that: isA<LoadMatchesEvent>()))).called(1);

      // Emit real success event from matches
      matchesController.add(initialMatchesState.copyWith(status: MatchesStatus.success));

      // Advance animation for progress bar to reach 100% and exit
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(currentPath, equals('/'));
      expect(find.text('Home Screen'), findsOneWidget);

      await homeController.close();
      await matchesController.close();
    });

    testWidgets('handles no internet connection: stays on splash until connection is restored', (tester) async {
      String currentPath = '/splash';
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      final testRouter = GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(
            path: '/splash',
            builder: (context, state) => const SplashView(),
          ),
          GoRoute(
            path: '/',
            builder: (context, state) {
              currentPath = '/';
              return const Scaffold(body: Text('Home Screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
        ),
      );

      // Allow network check to complete
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify offline icon, title, and Try Again button are visible
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.text('No internet connection'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      // Verify "Continue Offline" button has been completely removed
      expect(find.text('Continue Offline'), findsNothing);

      // Tapping anywhere on the screen does NOT navigate away when offline
      await tester.tap(find.byType(SplashView));
      await tester.pumpAndSettle();
      expect(currentPath, equals('/splash'));
      expect(find.byType(SplashView), findsOneWidget);
    });

    testWidgets('tapping Try Again in offline mode retries connection check', (tester) async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: SplashView(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      // Now simulate internet restored
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

      // Tap "Try Again"
      await tester.tap(find.text('Try Again'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));

      // Verify offline banner disappears and real loading resumes
      expect(find.byIcon(Icons.wifi_off_rounded), findsNothing);
      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('renders with zero overflow on small 320px screen width', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: SplashView(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(milliseconds: 1000));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders title in LTR order (154 then SCORE) even in Arabic locale', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('ar'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: SplashView(),
          ),
        ),
      );
      await tester.pump();

      final pos154 = tester.getTopLeft(find.text('154'));
      final posScore = tester.getTopLeft(find.text('SCORE'));

      // 154 must be to the left of SCORE (dx of 154 < dx of SCORE)
      expect(pos154.dx, lessThan(posScore.dx));

      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('adapts background and text colors to Light and Dark themes', (tester) async {
      // 1. Light Theme
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: Theme(
            data: ThemeData(brightness: Brightness.light),
            child: const SplashView(key: ValueKey('light')),
          ),
        ),
      );
      await tester.pump();

      final scaffoldLight = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffoldLight.backgroundColor, equals(AppColors.lightBackground));

      // 2. Dark Theme
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: Theme(
            data: ThemeData(brightness: Brightness.dark),
            child: const SplashView(key: ValueKey('dark')),
          ),
        ),
      );
      await tester.pump();

      final scaffoldDark = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffoldDark.backgroundColor, equals(AppColors.darkBackground));
    });
  });
}
