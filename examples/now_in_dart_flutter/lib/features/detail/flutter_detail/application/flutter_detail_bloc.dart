import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:now_in_dart_flutter/features/core/domain/fresh.dart';
import 'package:now_in_dart_flutter/features/detail/core/domain/detail.dart';
import 'package:now_in_dart_flutter/features/detail/core/domain/detail_failure.dart';
import 'package:now_in_dart_flutter/features/detail/flutter_detail/data/flutter_detail_repository.dart';

part 'flutter_detail_bloc.freezed.dart';
part 'flutter_detail_event.dart';
part 'flutter_detail_state.dart';

typedef _DetailFailureOrSuccess = Future<Either<DetailFailure, Fresh<Detail>>>;

class FlutterDetailBloc extends Bloc<FlutterDetailEvent, FlutterDetailState> {
  FlutterDetailBloc({
    required FlutterDetailRepository repository,
  })  : _repository = repository,
        super(const FlutterDetailState()) {
    on<FlutterDetailEvent>(
      (event, emit) async {
        await event.when<Future<void>>(
          flutterWhatsNewDetailRequested: (id) {
            return _onFlutterWhatsNewDetailRequested(emit, id);
          },
          flutterReleaseNotesDetailRequested: (id) {
            return _onFlutterReleaseNotesDetailRequested(emit, id);
          },
        );
      },
    );
  }

  final FlutterDetailRepository _repository;

  Future<void> _onFlutterWhatsNewDetailRequested(
    Emitter<FlutterDetailState> emit,
    int id,
  ) {
    return _onFlutterDetailRequested(
      _repository.getWhatsNewFlutterDetail,
      emit,
      id,
    );
  }

  Future<void> _onFlutterReleaseNotesDetailRequested(
    Emitter<FlutterDetailState> emit,
    int id,
  ) {
    return _onFlutterDetailRequested(
      _repository.getFlutterReleaseNotesDetail,
      emit,
      id,
    );
  }

  Future<void> _onFlutterDetailRequested(
    _DetailFailureOrSuccess Function(int) caller,
    Emitter<FlutterDetailState> emit,
    int id,
  ) async {
    emit(state.copyWith(status: () => FlutterDetailStatus.loading));
    final failureOrSuccessDetail = await caller(id);
    return failureOrSuccessDetail.fold(
      (failure) => emit(
        state.copyWith(
          status: () => FlutterDetailStatus.failure,
          failureMessage: () => failure.when<String>(
            api: (errorCode) => 'API returned $errorCode',
          ),
        ),
      ),
      (detail) => emit(
        state.copyWith(
          status: () => FlutterDetailStatus.success,
          detail: () => detail,
          failureMessage: () => null,
        ),
      ),
    );
  }
}
