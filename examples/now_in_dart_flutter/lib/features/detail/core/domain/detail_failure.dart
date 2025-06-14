import 'package:freezed_annotation/freezed_annotation.dart';

part 'detail_failure.freezed.dart';

@freezed
class DetailFailure with _$DetailFailure {
  const factory DetailFailure.api(int? errorCode) = _Api;
}
