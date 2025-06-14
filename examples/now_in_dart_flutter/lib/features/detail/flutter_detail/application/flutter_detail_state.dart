part of 'flutter_detail_bloc.dart';

enum FlutterDetailStatus { initial, loading, success, failure }

class FlutterDetailState extends Equatable {
  const FlutterDetailState({
    this.status = FlutterDetailStatus.initial,
    this.detail = const Fresh.yes(entity: Detail.empty),
    this.failureMessage,
  });

  final FlutterDetailStatus status;
  final Fresh<Detail> detail;
  final String? failureMessage;

  FlutterDetailState copyWith({
    FlutterDetailStatus Function()? status,
    Fresh<Detail> Function()? detail,
    String? Function()? failureMessage,
  }) {
    return FlutterDetailState(
      status: status != null ? status() : this.status,
      detail: detail != null ? detail() : this.detail,
      failureMessage:
          failureMessage != null ? failureMessage() : this.failureMessage,
    );
  }

  @override
  List<Object?> get props => [status, detail, failureMessage];
}
