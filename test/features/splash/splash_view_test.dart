import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:ysscores/features/splash/presentation/views/splash_view.dart';

void main() {
  group('SplashView Widget & Animation Tests', () {
    testWidgets('renders all brand, logo, title, and progress bar elements cleanly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const SplashView(),
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
