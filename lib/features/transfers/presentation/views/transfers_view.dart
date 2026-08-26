import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('transfers_title')),
      ),
      body: BlocBuilder<TransfersBloc, TransfersState>(
        builder: (context, state) {
          return Column(
            children: [
              // Search Input Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.translate('search_placeholder'),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    filled: true,
                    fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  onChanged: (val) {
                    context.read<TransfersBloc>().add(SearchTransfersEvent(val));
                  },
                ),
              ),

              // Transfers List
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    context.read<TransfersBloc>().add(const LoadTransfersEvent(isRefresh: true));
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
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (state.status == TransfersStatus.error) {
      return ErrorView(
        message: state.errorMessage,
        onRetry: () => context.read<TransfersBloc>().add(const LoadTransfersEvent()),
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
