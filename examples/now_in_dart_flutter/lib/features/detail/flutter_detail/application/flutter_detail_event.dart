part of 'flutter_detail_bloc.dart';

@freezed
class FlutterDetailEvent with _$FlutterDetailEvent {
  const factory FlutterDetailEvent.flutterWhatsNewDetailRequested(int id) =
      _FlutterWhatsNewDetailRequested;

  const factory FlutterDetailEvent.flutterReleaseNotesDetailRequested(int id) =
      _FlutterReleaseNotesDetailRequested;
}
