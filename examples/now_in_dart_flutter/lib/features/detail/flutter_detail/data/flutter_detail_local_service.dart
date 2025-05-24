import 'package:now_in_dart_flutter/features/detail/core/data/detail_dto.dart';
import 'package:now_in_dart_flutter/features/detail/core/data/detail_local_service.dart';

class FlutterDetailLocalService extends DetailLocalService {
  FlutterDetailLocalService({super.isarDb});

  Future<void> upsertFlutterDetail(DetailDTO detailDTO) {
    return super.upsertDetail(detailDTO);
  }

  Future<DetailDTO?> getFlutterDetail(int id) => super.getDetail(id);
}
