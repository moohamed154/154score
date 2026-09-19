import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:score154/features/home/presentation/cubit/home_cubit.dart';
import 'package:score154/features/matches/presentation/bloc/matches_bloc.dart';
import 'package:score154/features/matches/presentation/bloc/matches_event.dart';
import 'package:score154/features/matches/presentation/bloc/matches_state.dart';
import 'package:score154/features/splash/presentation/views/splash_view.dart';

class MockHomeCubit extends Mock implements HomeCubit {}
class MockMatchesBloc extends Mock implements MatchesBloc {}

void main() {
  setUpAll(() {
    registerFallbackValue(LoadMatchesEvent(date: DateTime.now()));
  });

  group('SplashView Widget & Animation Tests', () {
    testWidgets('renders all brand, logo, title, and progress bar elements cleanly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashView(),
        ),
      );

      // Verify immediate presence of scaffold and icon
      expect(find.byType(SplashView), findsOneWidget);
      expect(find.byIcon(Icons.sports_soccer_rounded), findsOneWidget);
      expect(find.text('154'), findsOneWidget);
      expect(find.text('SCORE'), findsOneWidget);
      expect(find.text('154SCORE v1.0.0'), findsOneWidget);

      // Advance animation halfway
      await tester.pump(const Duration(milliseconds: 1200));

      expect(find.byType(SplashView), findsOneWidget);

      // Advance animation to completion
      await tester.pump(const Duration(milliseconds: 1400));
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
        ),
      );

      expect(find.byType(SplashView), findsOneWidget);

      // Tap on screen to skip
      await tester.tap(find.byType(SplashView));
      await tester.pumpAndSettle();

      expect(currentPath, equals('/'));
      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('auto-navigates to / when animation completes', (tester) async {
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
        ),
      );

      expect(find.byType(SplashView), findsOneWidget);

      // Let the full animation run
      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pumpAndSettle();

      expect(currentPath, equals('/'));
      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets('triggers background preload for HomeCubit and MatchesBloc when present in context', (tester) async {
      final mockHome = MockHomeCubit();
      final mockMatches = MockMatchesBloc();

      when(() => mockHome.state).thenReturn(const HomeState(status: HomeStatus.initial));
      when(() => mockHome.loadHomeData()).thenAnswer((_) async {});
      when(() => mockHome.stream).thenAnswer((_) => const Stream<HomeState>.empty());

      final dummyMatchesState = MatchesState(
        selectedDate: DateTime(2026, 9, 20),
        status: MatchesStatus.initial,
      );
      when(() => mockMatches.state).thenReturn(dummyMatchesState);
      when(() => mockMatches.stream).thenAnswer((_) => const Stream<MatchesState>.empty());

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<HomeCubit>.value(value: mockHome),
            BlocProvider<MatchesBloc>.value(value: mockMatches),
          ],
          child: const MaterialApp(
            home: SplashView(),
          ),
        ),
      );

      // Immediately after mount, preload has not triggered yet (waiting 120ms post frame)
      verifyNever(() => mockHome.loadHomeData());

      // Advance by 200ms to trigger the staggered background preload
      await tester.pump(const Duration(milliseconds: 200));

      verify(() => mockHome.loadHomeData()).called(1);
      verify(() => mockMatches.add(any(that: isA<LoadMatchesEvent>()))).called(1);
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
          home: SplashView(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(milliseconds: 1000));
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(milliseconds: 1500));
      expect(tester.takeException(), isNull);
    });
  });
}
