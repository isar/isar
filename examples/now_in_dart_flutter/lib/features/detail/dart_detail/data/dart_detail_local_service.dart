import 'package:now_in_dart_flutter/features/detail/core/data/detail_dto.dart';
import 'package:now_in_dart_flutter/features/detail/core/data/detail_local_service.dart';

class DartDetailLocalService extends DetailLocalService {
  DartDetailLocalService({super.isarDb});

  Future<void> upsertDartDetail(DetailDTO detailDTO) {
    return super.upsertDetail(detailDTO);
  }

  Future<DetailDTO?> getDartDetail(int id) => super.getDetail(id);
}
