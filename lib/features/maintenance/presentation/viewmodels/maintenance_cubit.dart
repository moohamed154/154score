import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/maintenance_info.dart';
import '../../domain/repositories/maintenance_repository.dart';

enum MaintenanceStatus { initial, checking, active, resolved, error }

class MaintenanceState extends Equatable {
  final MaintenanceStatus status;
  final MaintenanceInfo? info;
  final String? errorMessage;

  const MaintenanceState({
    this.status = MaintenanceStatus.initial,
    this.info,
    this.errorMessage,
  });

  MaintenanceState copyWith({
    MaintenanceStatus? status,
    MaintenanceInfo? info,
    String? errorMessage,
  }) {
    return MaintenanceState(
      status: status ?? this.status,
      info: info ?? this.info,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, info, errorMessage];
}

class MaintenanceCubit extends Cubit<MaintenanceState> {
  final MaintenanceRepository _repository;

  MaintenanceCubit(this._repository) : super(const MaintenanceState());

  void setInitialInfo(MaintenanceInfo info) {
    emit(state.copyWith(
      status: info.isMaintenanceMode
          ? MaintenanceStatus.active
          : MaintenanceStatus.resolved,
      info: info,
    ));
  }

  Future<bool> checkStatus() async {
    emit(state.copyWith(status: MaintenanceStatus.checking));
    try {
      final info = await _repository.checkMaintenanceStatus();
      if (info.isMaintenanceMode) {
        emit(state.copyWith(
          status: MaintenanceStatus.active,
          info: info,
        ));
        return false;
      } else {
        emit(state.copyWith(
          status: MaintenanceStatus.resolved,
          info: info,
        ));
        return true;
      }
    } catch (e) {
      emit(state.copyWith(
        status: MaintenanceStatus.error,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }
}
