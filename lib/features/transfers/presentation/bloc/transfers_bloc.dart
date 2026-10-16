import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/realtime_merge_engine.dart';
import '../../../../core/websocket/websocket_event.dart';
import '../../../../core/websocket/websocket_service.dart';
import '../../domain/entities/transfer_entity.dart';
import '../../domain/repositories/transfers_repository.dart';

abstract class TransfersEvent extends Equatable {
  const TransfersEvent();

  @override
  List<Object?> get props => [];
}

class LoadTransfersEvent extends TransfersEvent {
  final bool isRefresh;
  final Completer<void>? completer;

  const LoadTransfersEvent({this.isRefresh = false, this.completer});

  @override
  List<Object?> get props => [isRefresh];
}

class SearchTransfersEvent extends TransfersEvent {
  final String query;

  const SearchTransfersEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class TransferSocketUpdateEvent extends TransfersEvent {
  final TransferUpdate update;

  const TransferSocketUpdateEvent(this.update);

  @override
  List<Object?> get props => [update];
}

class ChangeTransfersLanguageEvent extends TransfersEvent {
  final String languageCode;
  final Completer<void>? completer;

  const ChangeTransfersLanguageEvent(this.languageCode, {this.completer});

  @override
  List<Object?> get props => [languageCode];
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
  final WebSocketService? webSocketService;

  StreamSubscription? _wsSubscription;

  TransfersBloc({
    required this.repository,
    required this.localStorageService,
    this.webSocketService,
  }) : super(const TransfersState()) {
    on<LoadTransfersEvent>(_onLoadTransfers);
    on<SearchTransfersEvent>(_onSearchTransfers);
    on<TransferSocketUpdateEvent>(_onTransferSocketUpdate);
    on<ChangeTransfersLanguageEvent>(_onChangeTransfersLanguage);

    if (webSocketService != null) {
      webSocketService!.subscribeTransfers();
      _wsSubscription = webSocketService!.transfersStream.listen((update) {
        add(TransferSocketUpdateEvent(update));
      });
    }
  }

  Future<void> _onLoadTransfers(
    LoadTransfersEvent event,
    Emitter<TransfersState> emit,
  ) async {
    try {
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
    } finally {
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
    }
  }

  void _onSearchTransfers(
    SearchTransfersEvent event,
    Emitter<TransfersState> emit,
  ) {
    final filtered = _applySearch(state.allTransfers, event.query);
    emit(state.copyWith(searchQuery: event.query, filteredTransfers: filtered));
  }

  void _onTransferSocketUpdate(
    TransferSocketUpdateEvent event,
    Emitter<TransfersState> emit,
  ) {
    final mergeResult = RealtimeMergeEngine.mergeTransfersWithRealtime(
      existingTransfers: state.allTransfers,
      update: event.update,
    );

    if (mergeResult.isUpdated) {
      final filtered = _applySearch(mergeResult.data, state.searchQuery);
      emit(
        state.copyWith(
          status: TransfersStatus.success,
          allTransfers: mergeResult.data,
          filteredTransfers: filtered,
        ),
      );
    }
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

  Future<void> _onChangeTransfersLanguage(
    ChangeTransfersLanguageEvent event,
    Emitter<TransfersState> emit,
  ) async {
    final targetLang = event.languageCode;
    try {
      final result = await repository.getTransfers(lang: targetLang);

      // Race condition check: ensure current language is still targetLang
      final currentLang = localStorageService.getLanguage();
      if (currentLang != targetLang) return;

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
          // Keep existing transfers visible
        },
      );
    } catch (_) {
      // Keep existing transfers visible
    } finally {
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
    }
  }

  @override
  Future<void> close() {
    webSocketService?.unsubscribeTransfers();
    _wsSubscription?.cancel();
    return super.close();
  }
}
