import 'package:dartz/dartz.dart';
import 'package:now_in_dart_flutter/features/core/data/network_exception.dart';
import 'package:now_in_dart_flutter/features/core/domain/fresh.dart';
import 'package:now_in_dart_flutter/features/detail/core/data/detail_dto.dart';
import 'package:now_in_dart_flutter/features/detail/core/domain/detail.dart';
import 'package:now_in_dart_flutter/features/detail/core/domain/detail_failure.dart';
import 'package:now_in_dart_flutter/features/detail/dart_detail/data/dart_detail_local_service.dart';
import 'package:now_in_dart_flutter/features/detail/dart_detail/data/dart_detail_remote_service.dart';

typedef _DartDetailOrFailure = Future<Either<DetailFailure, Fresh<Detail>>>;

class DartDetailRepository {
  DartDetailRepository({
    DartDetailLocalService? localService,
    DartDetailRemoteService? remoteService,
  })  : _localService = localService ?? DartDetailLocalService(),
        _remoteService = remoteService ?? DartDetailRemoteService();

  final DartDetailLocalService _localService;
  final DartDetailRemoteService _remoteService;

  _DartDetailOrFailure getDartDetail(int id) async {
    try {
      final remoteResponse = await _remoteService.getDartChangelogDetail(id);
      return right(
        await remoteResponse.when(
          noConnection: () async {
            final dto = await _localService.getDartDetail(id);
            return Fresh.no(entity: dto?.toDomain() ?? Detail.empty);
          },
          notModified: () async {
            final cachedData = await _localService.getDartDetail(id);
            return Fresh.yes(entity: cachedData?.toDomain() ?? Detail.empty);
          },
          withNewData: (html) async {
            final dto = DetailDTO.parseHtml(id, html);
            await _localService.upsertDartDetail(dto);
            return Fresh.yes(entity: dto.toDomain());
          },
        ),
      );
    } on RestApiException catch (e) {
      return left(DetailFailure.api(e.errorCode));
    }
  }
}
