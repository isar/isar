part of 'dart_detail_bloc.dart';

enum DartDetailStatus { initial, loading, success, failure }

class DartDetailState extends Equatable {
  const DartDetailState({
    this.status = DartDetailStatus.initial,
    this.detail = const Fresh.yes(entity: Detail.empty),
    this.failureMessage,
  });

  final DartDetailStatus status;
  final Fresh<Detail> detail;
  final String? failureMessage;

  DartDetailState copyWith({
    DartDetailStatus Function()? status,
    Fresh<Detail> Function()? detail,
    String? Function()? failureMessage,
  }) {
    return DartDetailState(
      status: status != null ? status() : this.status,
      detail: detail != null ? detail() : this.detail,
      failureMessage:
          failureMessage != null ? failureMessage() : this.failureMessage,
    );
  }

  @override
  List<Object?> get props => [status, detail, failureMessage];
}
