import 'package:now_in_dart_flutter/app/app.dart';
import 'package:now_in_dart_flutter/bootstrap.dart';
import 'package:now_in_dart_flutter/features/detail/dart_detail/data/dart_detail_remote_service.dart';
import 'package:now_in_dart_flutter/features/detail/dart_detail/data/dart_detail_repository.dart';
import 'package:now_in_dart_flutter/features/detail/flutter_detail/data/flutter_detail_remote_service.dart';
import 'package:now_in_dart_flutter/features/detail/flutter_detail/data/flutter_detail_repository.dart';

void main() {
  bootstrap(
    (dio) {
      final dartDetailRepository = DartDetailRepository(
        remoteService: DartDetailRemoteService(dio: dio),
      );

      final flutterDetailRepository = FlutterDetailRepository(
        remoteService: FlutterDetailRemoteService(dio: dio),
      );

      return App(
        dartDetailRepository: dartDetailRepository,
        flutterDetailRepository: flutterDetailRepository,
      );
    },
  );
}
