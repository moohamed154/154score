import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/notifications/notification_sync_service.dart';
import '../../../../core/widgets/app_brand_logo.dart';
import '../../../favorites/presentation/cubit/favorites_cubit.dart';
import '../../../settings/presentation/cubit/settings_cubits.dart';
import '../../domain/entities/onboarding_catalog.dart';
import '../viewmodels/onboarding_cubit.dart';
import '../widgets/onboarding_widgets.dart';

/// First-launch setup flow: language, theme, favorite teams and leagues.
/// Shown only once (see `OnboardingRepository`).
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  bool _finishing = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _animateTo(int page) {
    if (!_pageController.hasClients) return;
    final current = _pageController.page?.round() ?? 0;
    if (current == page) return;
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish({required bool applySelections}) async {
    if (_finishing) return;
    setState(() => _finishing = true);

    final cubit = context.read<OnboardingCubit>();
    final favorites = context.read<FavoritesCubit>();
    final isArabic = AppLocalizations.of(context).isArabic;
    final selection = cubit.state;

    if (applySelections) {
      if (selection.selectedLeagues.isNotEmpty) {
        final chosen = OnboardingCatalog.leagues
            .where((l) => selection.selectedLeagues.contains(l.ar))
            .toList();
        await favorites.registerCompetitionTitles({
          for (final l in chosen)
            if (l.id != null) l.id!: l.ar,
        });
        await favorites.setFavoriteCompetitions(
          chosen.map((l) => l.ar).toList(),
        );
      }

      for (final team in OnboardingCatalog.teams) {
        if (!selection.selectedTeams.contains(team.ar)) continue;
        await favorites.toggleTeam(team.nameFor(isArabic: isArabic), id: team.id);
      }
    }

    await cubit.complete();
  }

  void _onCompleted() {
    final router = GoRouter.of(context);
    router.go('/');
    final pending = AppRouter.consumePendingRoute();
    if (pending != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        router.push(pending);
      });
    }
    NotificationSyncService.instance.syncAllSubscriptions();
  }

  @override
  Widget build(BuildContext context) {
    // Watch LocaleCubit and ThemeCubit so onboarding immediately reacts to user language/theme selection
    context.watch<LocaleCubit>();
    context.watch<ThemeCubit>();
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MultiBlocListener(
      listeners: [
        BlocListener<OnboardingCubit, OnboardingState>(
          listenWhen: (p, c) => p.page != c.page,
          listener: (context, state) => _animateTo(state.page),
        ),
        BlocListener<OnboardingCubit, OnboardingState>(
          listenWhen: (p, c) =>
              p.status != c.status && c.status == OnboardingStatus.completed,
          listener: (context, state) => _onCompleted(),
        ),
      ],
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(
                l10n: l10n,
                isDark: isDark,
                onSkip: () => _finish(applySelections: false),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => context.read<OnboardingCubit>().goTo(i),
                  children: [
                    _LanguagePage(l10n: l10n, isDark: isDark),
                    _ThemePage(l10n: l10n, isDark: isDark),
                    _TeamsPage(l10n: l10n, isDark: isDark),
                    _LeaguesPage(l10n: l10n, isDark: isDark),
                  ],
                ),
              ),
              _BottomBar(
                isDark: isDark,
                finishing: _finishing,
                onFinish: () => _finish(applySelections: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.l10n,
    required this.isDark,
    required this.onSkip,
  });

  final AppLocalizations l10n;
  final bool isDark;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kOnboardingMaxWidth),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppDimensions.xxl,
            AppDimensions.sm,
            AppDimensions.md,
            0,
          ),
          child: Row(
            children: [
              AppBrandLogo(size: AppDimensions.logoSizeLg, isDark: isDark),
              const Spacer(),
              TextButton(
                onPressed: onSkip,
                child: Text(
                  l10n.translate('onb_skip'),
                  style: AppTypography.getButton(
                    isDark: isDark,
                    isArabic: l10n.isArabic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.isDark,
    required this.finishing,
    required this.onFinish,
  });

  final bool isDark;
  final bool finishing;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.isArabic;

    return BlocBuilder<OnboardingCubit, OnboardingState>(
      buildWhen: (p, c) => p.page != c.page,
      builder: (context, state) {
        final cubit = context.read<OnboardingCubit>();
        return Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kOnboardingMaxWidth),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppDimensions.xl,
                AppDimensions.sm,
                AppDimensions.xl,
                AppDimensions.xl,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: state.page > 0
                        ? IconButton(
                            onPressed: cubit.back,
                            tooltip: isArabic ? 'السابق' : 'Back',
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                            ),
                          )
                        : null,
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        OnboardingState.pageCount,
                        (i) => OnboardingDot(active: i == state.page),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.xxl,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd,
                          ),
                        ),
                      ),
                      onPressed: finishing
                          ? null
                          : (state.isLastPage ? onFinish : cubit.next),
                      child: finishing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              l10n.translate(
                                state.isLastPage ? 'onb_start' : 'onb_next',
                              ),
                              style: AppTypography.getButton(
                                isDark: true,
                                isArabic: isArabic,
                              ).copyWith(color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LanguagePage extends StatelessWidget {
  const _LanguagePage({required this.l10n, required this.isDark});

  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isArabic = l10n.isArabic;
    return OnboardingPageScaffold(
      icon: Icons.language_rounded,
      title: l10n.translate('onb_lang_title'),
      subtitle: l10n.translate('onb_lang_sub'),
      isDark: isDark,
      isArabic: isArabic,
      child: Column(
        children: [
          OnboardingChoiceCard(
            title: 'العربية',
            subtitle: 'Arabic',
            icon: Icons.translate_rounded,
            selected: isArabic,
            isDark: isDark,
            isArabic: isArabic,
            onTap: () =>
                context.read<LocaleCubit>().setLocale(const Locale('ar')),
          ),
          const SizedBox(height: AppDimensions.md),
          OnboardingChoiceCard(
            title: 'English',
            subtitle: 'الإنجليزية',
            icon: Icons.translate_rounded,
            selected: !isArabic,
            isDark: isDark,
            isArabic: isArabic,
            onTap: () =>
                context.read<LocaleCubit>().setLocale(const Locale('en')),
          ),
        ],
      ),
    );
  }
}

class _ThemePage extends StatelessWidget {
  const _ThemePage({required this.l10n, required this.isDark});

  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isArabic = l10n.isArabic;
    return OnboardingPageScaffold(
      icon: Icons.palette_rounded,
      title: l10n.translate('onb_theme_title'),
      subtitle: l10n.translate('onb_theme_sub'),
      isDark: isDark,
      isArabic: isArabic,
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, mode) {
          final cubit = context.read<ThemeCubit>();
          Widget card(ThemeMode value, String key, IconData icon) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.md),
              child: OnboardingChoiceCard(
                title: l10n.translate(key),
                icon: icon,
                selected: mode == value,
                isDark: isDark,
                isArabic: isArabic,
                onTap: () => cubit.setThemeMode(value),
              ),
            );
          }

          return Column(
            children: [
              card(ThemeMode.dark, 'theme_dark', Icons.dark_mode_rounded),
              card(ThemeMode.light, 'theme_light', Icons.light_mode_rounded),
              card(
                ThemeMode.system,
                'theme_system',
                Icons.settings_suggest_rounded,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TeamsPage extends StatelessWidget {
  const _TeamsPage({required this.l10n, required this.isDark});

  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isArabic = l10n.isArabic;
    return OnboardingPageScaffold(
      icon: Icons.shield_rounded,
      title: l10n.translate('onb_teams_title'),
      subtitle: l10n.translate('onb_teams_sub'),
      isDark: isDark,
      isArabic: isArabic,
      child: BlocBuilder<OnboardingCubit, OnboardingState>(
        buildWhen: (p, c) => p.selectedTeams != c.selectedTeams,
        builder: (context, state) {
          return OnboardingChips(
            items: OnboardingCatalog.teams,
            selected: state.selectedTeams,
            isArabic: isArabic,
            isDark: isDark,
            onToggle: (item) =>
                context.read<OnboardingCubit>().toggleTeam(item.ar),
          );
        },
      ),
    );
  }
}

class _LeaguesPage extends StatelessWidget {
  const _LeaguesPage({required this.l10n, required this.isDark});

  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isArabic = l10n.isArabic;
    return OnboardingPageScaffold(
      icon: Icons.emoji_events_rounded,
      title: l10n.translate('onb_leagues_title'),
      subtitle: l10n.translate('onb_leagues_sub'),
      isDark: isDark,
      isArabic: isArabic,
      child: BlocBuilder<OnboardingCubit, OnboardingState>(
        buildWhen: (p, c) => p.selectedLeagues != c.selectedLeagues,
        builder: (context, state) {
          return OnboardingChips(
            items: OnboardingCatalog.leagues,
            selected: state.selectedLeagues,
            isArabic: isArabic,
            isDark: isDark,
            isLeague: true,
            onToggle: (item) =>
                context.read<OnboardingCubit>().toggleLeague(item.ar),
          );
        },
      ),
    );
  }
}
