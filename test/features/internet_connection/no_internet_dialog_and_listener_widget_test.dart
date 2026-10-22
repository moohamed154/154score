import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:score154/core/localization/app_localizations.dart';
import 'package:score154/core/theme/app_theme.dart';
import 'package:score154/features/internet_connection/domain/entities/internet_connection_status.dart';
import 'package:score154/features/internet_connection/domain/repositories/internet_connection_repository.dart';
import 'package:score154/features/internet_connection/presentation/cubit/internet_connection_cubit.dart';
import 'package:score154/features/internet_connection/presentation/widgets/global_internet_connection_listener.dart';
import 'package:score154/features/internet_connection/presentation/widgets/no_internet_dialog.dart';

class MockInternetConnectionRepository extends Mock
    implements InternetConnectionRepository {}

void main() {
  late MockInternetConnectionRepository mockRepository;

  setUp(() {
    mockRepository = MockInternetConnectionRepository();
    when(() => mockRepository.onStatusChanged)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockRepository.dispose()).thenReturn(null);
  });

  Widget buildTestApp({
    required InternetConnectionCubit cubit,
    Locale locale = const Locale('ar'),
    ThemeMode themeMode = ThemeMode.dark,
    Widget? homeChild,
  }) {
    return BlocProvider<InternetConnectionCubit>.value(
      value: cubit,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        builder: (context, child) {
          return GlobalInternetConnectionListener(
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: homeChild ??
            const Scaffold(
              body: Center(
                child: Text('Underlying HomeScreen Content'),
              ),
            ),
      ),
    );
  }

  group('NoInternetDialog & GlobalInternetConnectionListener Widget Tests', () {
    testWidgets('renders Arabic copy, RTL direction, and blocks back button',
        (tester) async {
      when(() => mockRepository.checkInternetAccess())
          .thenAnswer((_) async => InternetConnectionStatus.disconnected);

      final cubit = InternetConnectionCubit(repository: mockRepository);
      await tester.pumpWidget(
        buildTestApp(cubit: cubit, locale: const Locale('ar')),
      );
      await tester.pumpAndSettle();

      // 1. Verify dialog appears
      expect(find.byType(NoInternetDialog), findsOneWidget);

      // 2. Verify Arabic copy
      expect(find.text('لا يوجد اتصال بالإنترنت'), findsOneWidget);
      expect(
        find.text('تأكد من اتصالك بالإنترنت وحاول مرة أخرى.'),
        findsOneWidget,
      );
      expect(find.text('إعادة المحاولة'), findsOneWidget);

      // 3. Verify RTL Directionality inside the dialog
      final directionalityFinder = find.descendant(
        of: find.byType(NoInternetDialog),
        matching: find.byType(Directionality),
      );
      expect(directionalityFinder, findsWidgets);
      final Directionality dirWidget =
          tester.widget(directionalityFinder.first);
      expect(dirWidget.textDirection, equals(TextDirection.rtl));

      // 4. Verify PopScope blocks popping
      final popScopeFinder = find.descendant(
        of: find.byType(NoInternetDialog),
        matching: find.byType(PopScope),
      );
      expect(popScopeFinder, findsOneWidget);
      final PopScope popScope = tester.widget(popScopeFinder);
      expect(popScope.canPop, isFalse);

      await cubit.close();
    });

    testWidgets('renders English copy and LTR direction', (tester) async {
      when(() => mockRepository.checkInternetAccess())
          .thenAnswer((_) async => InternetConnectionStatus.disconnected);

      final cubit = InternetConnectionCubit(repository: mockRepository);
      await tester.pumpWidget(
        buildTestApp(cubit: cubit, locale: const Locale('en')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NoInternetDialog), findsOneWidget);
      expect(find.text('No Internet Connection'), findsOneWidget);
      expect(
        find.text('Please check your internet connection and try again.'),
        findsOneWidget,
      );
      expect(find.text('Try Again'), findsOneWidget);

      final directionalityFinder = find.descendant(
        of: find.byType(NoInternetDialog),
        matching: find.byType(Directionality),
      );
      final Directionality dirWidget =
          tester.widget(directionalityFinder.first);
      expect(dirWidget.textDirection, equals(TextDirection.ltr));

      await cubit.close();
    });

    testWidgets('renders correctly in Light Theme and Dark Theme',
        (tester) async {
      when(() => mockRepository.checkInternetAccess())
          .thenAnswer((_) async => InternetConnectionStatus.disconnected);

      final cubit = InternetConnectionCubit(repository: mockRepository);

      // Test Light Theme
      await tester.pumpWidget(
        buildTestApp(
          cubit: cubit,
          themeMode: ThemeMode.light,
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NoInternetDialog), findsOneWidget);

      // Test Dark Theme
      await tester.pumpWidget(
        buildTestApp(
          cubit: cubit,
          themeMode: ThemeMode.dark,
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NoInternetDialog), findsOneWidget);

      await cubit.close();
    });

    testWidgets(
        'shows loading indicator while retrying and prevents duplicate taps',
        (tester) async {
      when(() => mockRepository.checkInternetAccess())
          .thenAnswer((_) async => InternetConnectionStatus.disconnected);

      final cubit = InternetConnectionCubit(repository: mockRepository);
      await tester.pumpWidget(
        buildTestApp(cubit: cubit, locale: const Locale('ar')),
      );
      await tester.pumpAndSettle();

      // Tap Retry button
      final retryFinder = find.text('إعادة المحاولة');
      expect(retryFinder, findsOneWidget);

      // Start retry check
      when(() => mockRepository.checkInternetAccess()).thenAnswer(
        (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 300));
          return InternetConnectionStatus.disconnected;
        },
      );

      await tester.tap(retryFinder);
      await tester.pump(const Duration(milliseconds: 50));

      // Loading spinner and "جارٍ التحقق من الاتصال..." should appear
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('جارٍ التحقق من الاتصال...'), findsOneWidget);

      await tester.pumpAndSettle();
      await cubit.close();
    });

    testWidgets(
        'automatically dismisses dialog when internet connectivity recovers',
        (tester) async {
      // 1. Starts disconnected
      when(() => mockRepository.checkInternetAccess())
          .thenAnswer((_) async => InternetConnectionStatus.disconnected);

      final cubit = InternetConnectionCubit(repository: mockRepository);
      await tester.pumpWidget(
        buildTestApp(cubit: cubit, locale: const Locale('ar')),
      );
      await tester.pumpAndSettle();

      // Dialog is visible blocking the screen
      expect(find.byType(NoInternetDialog), findsOneWidget);
      expect(find.text('Underlying HomeScreen Content'), findsOneWidget);

      // 2. Connectivity restored
      when(() => mockRepository.checkInternetAccess())
          .thenAnswer((_) async => InternetConnectionStatus.connected);

      await cubit.checkConnection();
      await tester.pumpAndSettle();

      // Dialog disappears automatically
      expect(find.byType(NoInternetDialog), findsNothing);

      // Underlying content is clearly visible and accessible
      expect(find.text('Underlying HomeScreen Content'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('multiple offline events do not create duplicate dialogs',
        (tester) async {
      when(() => mockRepository.checkInternetAccess())
          .thenAnswer((_) async => InternetConnectionStatus.disconnected);

      final cubit = InternetConnectionCubit(repository: mockRepository);
      await tester.pumpWidget(
        buildTestApp(cubit: cubit, locale: const Locale('en')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NoInternetDialog), findsOneWidget);

      // Emit another disconnected check
      await cubit.checkConnection();
      await tester.pumpAndSettle();

      // Exactly ONE dialog instance is displayed
      expect(find.byType(NoInternetDialog), findsOneWidget);

      await cubit.close();
    });
  });
}
