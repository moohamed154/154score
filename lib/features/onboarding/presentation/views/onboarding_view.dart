import 'package:flutter/services.dart';
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
        final titlesMap = <String, String>{};
        for (final l in chosen) {
          if (l.id != null) {
            titlesMap[l.id!] = l.ar;
            titlesMap[l.ar.toLowerCase()] = l.id!;
            titlesMap[l.en.toLowerCase()] = l.id!;
          }
        }
        await favorites.registerCompetitionTitles(titlesMap);
        await favorites.setFavoriteCompetitions(
          chosen.map((l) => l.ar).toList(),
        );
      } else {
        await favorites.setFavoriteCompetitions([]);
      }

      for (final team in OnboardingCatalog.teams) {
        if (!selection.selectedTeams.contains(team.ar)) continue;
        await favorites.toggleTeam(team.nameFor(isArabic: isArabic),
            id: team.id);
      }
    } else {
      await favorites.setFavoriteCompetitions([]);
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
    // Watch LocaleCubit, ThemeCubit, and FontSizeCubit so onboarding immediately reacts to user language/theme/font size selection
    context.watch<LocaleCubit>();
    context.watch<ThemeCubit>();
    context.watch<FontSizeCubit>();
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
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
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
                    _FontSizePage(l10n: l10n, isDark: isDark),
                    _TeamsPage(
                      key: ValueKey('teams_$isDark'),
                      l10n: l10n,
                      isDark: isDark,
                    ),
                    _LeaguesPage(
                      key: ValueKey('leagues_$isDark'),
                      l10n: l10n,
                      isDark: isDark,
                    ),
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

class _FontSizePage extends StatelessWidget {
  const _FontSizePage({required this.l10n, required this.isDark});

  final AppLocalizations l10n;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isArabic = l10n.isArabic;
    return OnboardingPageScaffold(
      icon: Icons.format_size_rounded,
      title: l10n.translate('onb_font_size_title'),
      subtitle: l10n.translate('onb_font_size_sub'),
      isDark: isDark,
      isArabic: isArabic,
      child: BlocBuilder<FontSizeCubit, FontSizeState>(
        builder: (context, fontState) {
          final cubit = context.read<FontSizeCubit>();
          final isAuto = fontState.isAuto;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Auto Option (System Default)
              OnboardingChoiceCard(
                title: l10n.translate('font_size_auto'),
                subtitle: l10n.translate('font_size_auto_desc'),
                icon: Icons.settings_suggest_rounded,
                selected: isAuto,
                isDark: isDark,
                isArabic: isArabic,
                onTap: () {
                  HapticFeedback.selectionClick();
                  cubit.setAuto(true);
                },
              ),
              const SizedBox(height: AppDimensions.md),

              // 2. Custom Size Option
              OnboardingChoiceCard(
                title: l10n.translate('font_size_manual'),
                subtitle: l10n.translate('font_size_manual_desc'),
                icon: Icons.text_fields_rounded,
                selected: !isAuto,
                isDark: isDark,
                isArabic: isArabic,
                onTap: () {
                  HapticFeedback.selectionClick();
                  cubit.setAuto(false);
                },
              ),

              // 3. Slider and Preset Controls (Shown when manual is selected)
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: !isAuto
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Padding(
                  padding: const EdgeInsets.only(top: AppDimensions.md),
                  child: Container(
                    padding: const EdgeInsets.all(AppDimensions.lg),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusLg),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              l10n.translate('font_size_app'),
                              style: AppTypography.getBodyMedium(
                                isDark: isDark,
                                isArabic: isArabic,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusSm,
                                ),
                              ),
                              child: Text(
                                '${(fontState.appFontSizeScale * 100).toInt()}%',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Preset Quick Chips
                        Row(
                          children: [
                            _buildPresetChip(
                              label: isArabic ? 'صغير' : 'Small',
                              targetScale: 0.85,
                              currentScale: fontState.appFontSizeScale,
                              isDark: isDark,
                              onTap: () => cubit.setAppFontSizeScale(0.85),
                            ),
                            const SizedBox(width: 8),
                            _buildPresetChip(
                              label: isArabic ? 'افتراضي' : 'Default',
                              targetScale: 1.0,
                              currentScale: fontState.appFontSizeScale,
                              isDark: isDark,
                              onTap: () => cubit.setAppFontSizeScale(1.0),
                            ),
                            const SizedBox(width: 8),
                            _buildPresetChip(
                              label: isArabic ? 'كبير' : 'Large',
                              targetScale: 1.15,
                              currentScale: fontState.appFontSizeScale,
                              isDark: isDark,
                              onTap: () => cubit.setAppFontSizeScale(1.15),
                            ),
                            const SizedBox(width: 8),
                            _buildPresetChip(
                              label: isArabic ? 'كبير جداً' : 'X-Large',
                              targetScale: 1.30,
                              currentScale: fontState.appFontSizeScale,
                              isDark: isDark,
                              onTap: () => cubit.setAppFontSizeScale(1.30),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Discrete Slider
                        _buildDiscreteSlider(
                          value: fontState.appFontSizeScale,
                          isDark: isDark,
                          onChanged: (val) {
                            cubit.setAppFontSizeScale(val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                secondChild: const SizedBox.shrink(),
              ),

              const SizedBox(height: AppDimensions.lg),

              // 4. Live Text Preview Box
              _buildLivePreview(
                context: context,
                isDark: isDark,
                isArabic: isArabic,
                fontState: fontState,
                l10n: l10n,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPresetChip({
    required String label,
    required double targetScale,
    required double currentScale,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final isSelected = (currentScale - targetScale).abs() < 0.04;
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildDiscreteSlider({
    required double value,
    required bool isDark,
    required ValueChanged<double> onChanged,
  }) {
    final clampedValue = value.clamp(0.80, 1.30);
    final mutedColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Row(
      children: [
        Text(
          'A',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: mutedColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3.5,
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: isDark
                  ? const Color(0xFF243242)
                  : const Color(0xFFE2E8F0),
              thumbColor: AppColors.primary,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 8.5,
                elevation: 2.0,
              ),
              overlayColor: AppColors.primary.withValues(alpha: 0.16),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18.0),
              tickMarkShape:
                  const RoundSliderTickMarkShape(tickMarkRadius: 2.0),
              activeTickMarkColor: Colors.black.withValues(alpha: 0.35),
              inactiveTickMarkColor: isDark
                  ? const Color(0xFF475569)
                  : const Color(0xFF94A3B8),
            ),
            child: Slider(
              value: clampedValue,
              min: 0.80,
              max: 1.30,
              divisions: 10,
              onChanged: (newVal) {
                HapticFeedback.selectionClick();
                onChanged(newVal);
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'A',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: mutedColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLivePreview({
    required BuildContext context,
    required bool isDark,
    required bool isArabic,
    required FontSizeState fontState,
    required AppLocalizations l10n,
  }) {
    final previewScaler = fontState.isAuto
        ? MediaQuery.of(context).textScaler
        : TextScaler.linear(fontState.appFontSizeScale);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161F30) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.preview_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'معاينة مباشرة للخط' : 'Live Font Preview',
                style: AppTypography.getBodySmall(
                  isDark: isDark,
                  isArabic: isArabic,
                ).copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                fontState.isAuto
                    ? l10n.translate('font_size_auto')
                    : '${(fontState.appFontSizeScale * 100).toInt()}%',
                style: AppTypography.getBodySmall(
                  isDark: isDark,
                  isArabic: isArabic,
                ).copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.translate('onb_font_size_preview'),
            textScaler: previewScaler,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamsPage extends StatelessWidget {
  const _TeamsPage({super.key, required this.l10n, required this.isDark});

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
  const _LeaguesPage({super.key, required this.l10n, required this.isDark});

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
