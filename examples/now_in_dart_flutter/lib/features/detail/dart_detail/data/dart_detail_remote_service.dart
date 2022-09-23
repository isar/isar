import 'package:now_in_dart_flutter/features/core/data/remote_response.dart';
import 'package:now_in_dart_flutter/features/detail/core/data/detail_remote_service.dart';

typedef _DartDetail = Future<RemoteResponse<String>>;

class DartDetailRemoteService extends DetailRemoteService {
  DartDetailRemoteService({
    super.dio,
    super.headerCache,
  });

  _DartDetail getDartChangelogDetail(int id) {
    const fullPathToMarkdownFile = 'repos/dart-lang/sdk/contents/CHANGELOG.md';
    return super.getDetail(id, fullPathToMarkdownFile);
  }
}
