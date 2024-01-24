part of 'dart_detail_bloc.dart';

@freezed
class DartDetailEvent with _$DartDetailEvent {
  const factory DartDetailEvent.dartChangelogDetailRequested(int id) =
      _DartChangelogDetailRequested;
}
