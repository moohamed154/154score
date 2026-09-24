import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_brand_logo.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../domain/entities/transfer_entity.dart';
import '../bloc/transfers_bloc.dart';
import '../widgets/transfer_card.dart';

class TransfersView extends StatefulWidget {
  const TransfersView({super.key});

  @override
  State<TransfersView> createState() => _TransfersViewState();
}

class _TransfersViewState extends State<TransfersView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final bloc = context.read<TransfersBloc>();
    if (bloc.state.status == TransfersStatus.initial) {
      bloc.add(const LoadTransfersEvent());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = l10n.isArabic;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBrandLogo(size: 32, isDark: isDark),
            const SizedBox(width: 10),
            Text(
              '154Score',
              style: AppTypography.getHeadingLarge(
                isDark: isDark,
                isArabic: isArabic,
              ).copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
      body: BlocBuilder<TransfersBloc, TransfersState>(
        builder: (context, state) {
          return Column(
            children: [
              // Search Input Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.lg,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.translate('search_placeholder'),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkCard
                        : AppColors.lightCard,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusFull,
                      ),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusFull,
                      ),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusFull,
                      ),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  onChanged: (val) {
                    context.read<TransfersBloc>().add(
                      SearchTransfersEvent(val),
                    );
                  },
                ),
              ),

              // Transfers List
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    final completer = Completer<void>();
                    context.read<TransfersBloc>().add(
                      LoadTransfersEvent(isRefresh: true, completer: completer),
                    );
                    try {
                      await completer.future.timeout(
                        const Duration(seconds: 3),
                      );
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

  Widget _buildBody(BuildContext context, TransfersState state) {
    if (state.status == TransfersStatus.loading) {
      return Skeletonizer(
        enabled: true,
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: AppDimensions.xxxl),
          itemCount: 8,
          itemBuilder: (_, __) => const TransferCard(
            transfer: TransferEntity(
              id: 'dummy',
              playerName: 'Player Full Name Placeholder',
              playerPosition: 'Midfielder',
              fromTeamName: 'Previous Football Club',
              toTeamName: 'Target Football Club',
              transferType: 'Permanent Transfer',
              transferPrice: '€50,000,000',
              date: '2025-07-01',
            ),
          ),
        ),
      );
    }

    if (state.status == TransfersStatus.error) {
      return ErrorView(
        message: state.errorMessage,
        onRetry: () =>
            context.read<TransfersBloc>().add(const LoadTransfersEvent()),
      );
    }

    if (state.filteredTransfers.isEmpty) {
      return const EmptyView(
        titleKey: 'no_transfers',
        icon: Icons.swap_horiz_rounded,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppDimensions.xxxl),
      itemCount: state.filteredTransfers.length,
      itemBuilder: (context, index) {
        return TransferCard(transfer: state.filteredTransfers[index]);
      },
    );
  }
}
