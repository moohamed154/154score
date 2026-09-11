import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../domain/entities/video_entity.dart';
import '../bloc/videos_bloc.dart';
import '../widgets/video_card.dart';

class VideosView extends StatefulWidget {
  const VideosView({super.key});

  @override
  State<VideosView> createState() => _VideosViewState();
}

class _VideosViewState extends State<VideosView> {
  @override
  void initState() {
    super.initState();
    final bloc = context.read<VideosBloc>();
    if (bloc.state.status == VideosStatus.initial) {
      bloc.add(const LoadVideosEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('videos_title'))),
      body: BlocBuilder<VideosBloc, VideosState>(
        builder: (context, state) {
          return Column(
            children: [
              // Categories Carousel
              if (state.categories.isNotEmpty)
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.lg,
                    ),
                    itemCount: state.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = state.categories[index];
                      final isSelected = state.selectedCategory == cat.id;

                      return ChoiceChip(
                        showCheckmark: false,
                        selected: isSelected,
                        onSelected: (_) {
                          context.read<VideosBloc>().add(
                            SelectVideoCategoryEvent(cat.id),
                          );
                        },
                        backgroundColor: isDark
                            ? AppColors.darkCard
                            : AppColors.lightCard,
                        selectedColor: AppColors.primary,
                        side: BorderSide(
                          color: isSelected
                              ? Colors.transparent
                              : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusFull,
                          ),
                        ),
                        label: Text(
                          cat.title,
                          style:
                              AppTypography.getBodySmall(
                                isDark: isDark,
                                isArabic: isArabic,
                              ).copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.black
                                    : (isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary),
                              ),
                        ),
                      );
                    },
                  ),
                ),

              // Videos List
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    final completer = Completer<void>();
                    context.read<VideosBloc>().add(
                      LoadVideosEvent(
                        champId: state.selectedCategory,
                        isRefresh: true,
                        completer: completer,
                      ),
                    );
                    try {
                      await completer.future.timeout(const Duration(seconds: 3));
                    } catch (_) {}
                  },
                  child: _buildBody(context, state),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, VideosState state) {
    if (state.status == VideosStatus.loading) {
      return Skeletonizer(
        enabled: true,
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: AppDimensions.xxxl),
          itemCount: 6,
          itemBuilder: (_, __) => const VideoCard(
            video: VideoItemEntity(
              id: 'dummy',
              title: 'Match Highlights and Goals Video Title',
              championship: 'UEFA Champions League',
              date: '2025-01-01',
            ),
          ),
        ),
      );
    }

    if (state.status == VideosStatus.error) {
      return ErrorView(
        message: state.errorMessage,
        onRetry: () => context.read<VideosBloc>().add(
          LoadVideosEvent(champId: state.selectedCategory),
        ),
      );
    }

    if (state.videos.isEmpty) {
      return const EmptyView(
        titleKey: 'no_videos',
        icon: Icons.video_library_rounded,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppDimensions.xxxl),
      itemCount: state.videos.length,
      itemBuilder: (context, index) {
        return VideoCard(video: state.videos[index]);
      },
    );
  }
}
