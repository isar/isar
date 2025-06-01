import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:now_in_dart_flutter/features/core/domain/fresh.dart';
import 'package:now_in_dart_flutter/features/detail/core/domain/detail.dart';
import 'package:now_in_dart_flutter/features/detail/dart_detail/data/dart_detail_repository.dart';

part 'dart_detail_bloc.freezed.dart';
part 'dart_detail_event.dart';
part 'dart_detail_state.dart';

class DartDetailBloc extends Bloc<DartDetailEvent, DartDetailState> {
  DartDetailBloc({
    required DartDetailRepository repository,
  })  : _repository = repository,
        super(const DartDetailState()) {
    on<DartDetailEvent>(
      (event, emit) async {
        await event.when<Future<void>>(
          dartChangelogDetailRequested: (id) {
            return _onDartChangelogDetailRequested(emit, id);
          },
        );
      },
    );
  }

  final DartDetailRepository _repository;

  Future<void> _onDartChangelogDetailRequested(
    Emitter<DartDetailState> emit,
    int id,
  ) async {
    emit(state.copyWith(status: () => DartDetailStatus.loading));
    final failureOrSuccessDetail = await _repository.getDartDetail(id);
    return failureOrSuccessDetail.fold(
      (failure) => emit(
        state.copyWith(
          status: () => DartDetailStatus.failure,
          failureMessage: () => failure.when<String>(
            api: (errorCode) => 'API returned $errorCode',
          ),
        ),
      ),
      (detail) => emit(
        state.copyWith(
          status: () => DartDetailStatus.success,
          detail: () => detail,
          failureMessage: () => null,
        ),
      ),
    );
  }
}
