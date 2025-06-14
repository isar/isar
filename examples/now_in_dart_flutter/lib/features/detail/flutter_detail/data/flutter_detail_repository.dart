import 'package:dartz/dartz.dart';
import 'package:now_in_dart_flutter/features/core/data/network_exception.dart';
import 'package:now_in_dart_flutter/features/core/data/remote_response.dart';
import 'package:now_in_dart_flutter/features/core/domain/fresh.dart';
import 'package:now_in_dart_flutter/features/detail/core/data/detail_dto.dart';
import 'package:now_in_dart_flutter/features/detail/core/domain/detail.dart';
import 'package:now_in_dart_flutter/features/detail/core/domain/detail_failure.dart';
import 'package:now_in_dart_flutter/features/detail/flutter_detail/data/flutter_detail_local_service.dart';
import 'package:now_in_dart_flutter/features/detail/flutter_detail/data/flutter_detail_remote_service.dart';

typedef _FlutterDetailOrFailure = Future<Either<DetailFailure, Fresh<Detail>>>;

class FlutterDetailRepository {
  FlutterDetailRepository({
    FlutterDetailLocalService? localService,
    FlutterDetailRemoteService? remoteService,
  })  : _localService = localService ?? FlutterDetailLocalService(),
        _remoteService = remoteService ?? FlutterDetailRemoteService();

  final FlutterDetailLocalService _localService;
  final FlutterDetailRemoteService _remoteService;

  _FlutterDetailOrFailure getWhatsNewFlutterDetail(int id) {
    return _getFlutterDetail(id, _remoteService.getWhatsNewFlutterDetail);
  }

  _FlutterDetailOrFailure getFlutterReleaseNotesDetail(int id) {
    return _getFlutterDetail(id, _remoteService.getFlutterReleaseNotesDetail);
  }

  _FlutterDetailOrFailure _getFlutterDetail(
    int id,
    Future<RemoteResponse<String>> Function(int) caller,
  ) async {
    try {
      final remoteResponse = await caller(id);
      return right(
        await remoteResponse.when(
          noConnection: () async {
            final dto = await _localService.getFlutterDetail(id);
            return Fresh.no(entity: dto?.toDomain() ?? Detail.empty);
          },
          notModified: () async {
            final cachedData = await _localService.getFlutterDetail(id);
            return Fresh.yes(entity: cachedData?.toDomain() ?? Detail.empty);
          },
          withNewData: (html) async {
            final dto = DetailDTO.parseHtml(id, html);
            await _localService.upsertFlutterDetail(dto);
            return Fresh.yes(entity: dto.toDomain());
          },
        ),
      );
    } on RestApiException catch (e) {
      return left(DetailFailure.api(e.errorCode));
    }
  }
}
