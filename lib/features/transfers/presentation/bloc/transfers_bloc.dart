import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/local_storage_service.dart';
import '../../domain/entities/transfer_entity.dart';
import '../../domain/repositories/transfers_repository.dart';

abstract class TransfersEvent extends Equatable {
  const TransfersEvent();

  @override
  List<Object?> get props => [];
}

class LoadTransfersEvent extends TransfersEvent {
  final bool isRefresh;

  const LoadTransfersEvent({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
}

class SearchTransfersEvent extends TransfersEvent {
  final String query;

  const SearchTransfersEvent(this.query);

  @override
  List<Object?> get props => [query];
}

enum TransfersStatus { initial, loading, success, empty, error }

class TransfersState extends Equatable {
  final TransfersStatus status;
  final List<TransferEntity> allTransfers;
  final List<TransferEntity> filteredTransfers;
  final String searchQuery;
  final String? errorMessage;

  const TransfersState({
    this.status = TransfersStatus.initial,
    this.allTransfers = const [],
    this.filteredTransfers = const [],
    this.searchQuery = '',
    this.errorMessage,
  });

  TransfersState copyWith({
    TransfersStatus? status,
    List<TransferEntity>? allTransfers,
    List<TransferEntity>? filteredTransfers,
    String? searchQuery,
    String? errorMessage,
  }) {
    return TransfersState(
      status: status ?? this.status,
      allTransfers: allTransfers ?? this.allTransfers,
      filteredTransfers: filteredTransfers ?? this.filteredTransfers,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    allTransfers,
    filteredTransfers,
    searchQuery,
    errorMessage,
  ];
}

class TransfersBloc extends Bloc<TransfersEvent, TransfersState> {
  final TransfersRepository repository;
  final LocalStorageService localStorageService;

  TransfersBloc({required this.repository, required this.localStorageService})
    : super(const TransfersState()) {
    on<LoadTransfersEvent>(_onLoadTransfers);
    on<SearchTransfersEvent>(_onSearchTransfers);
  }

  Future<void> _onLoadTransfers(
    LoadTransfersEvent event,
    Emitter<TransfersState> emit,
  ) async {
    if (!event.isRefresh) {
      emit(state.copyWith(status: TransfersStatus.loading));
    }

    final lang = localStorageService.getLanguage();
    final result = await repository.getTransfers(lang: lang);

    result.fold(
      onSuccess: (transfers) {
        final filtered = _applySearch(transfers, state.searchQuery);
        emit(
          state.copyWith(
            status: transfers.isEmpty
                ? TransfersStatus.empty
                : TransfersStatus.success,
            allTransfers: transfers,
            filteredTransfers: filtered,
            errorMessage: null,
          ),
        );
      },
      onFailure: (failure) {
        emit(
          state.copyWith(
            status: TransfersStatus.error,
            errorMessage: failure.message,
          ),
        );
      },
    );
  }

  void _onSearchTransfers(
    SearchTransfersEvent event,
    Emitter<TransfersState> emit,
  ) {
    final filtered = _applySearch(state.allTransfers, event.query);
    emit(state.copyWith(searchQuery: event.query, filteredTransfers: filtered));
  }

  List<TransferEntity> _applySearch(List<TransferEntity> list, String query) {
    if (query.trim().isEmpty) return list;
    final q = query.trim().toLowerCase();
    return list.where((t) {
      return t.playerName.toLowerCase().contains(q) ||
          (t.fromTeamName?.toLowerCase().contains(q) ?? false) ||
          (t.toTeamName?.toLowerCase().contains(q) ?? false) ||
          (t.playerPosition?.toLowerCase().contains(q) ?? false);
    }).toList();
  }
}
