import 'package:isar_generator/src/object_info.dart';

import 'package:dartx/dartx.dart';

String getCollectionVar(String objectType) =>
    '_${objectType.decapitalize()}Collection';

String getAdapterName(String objectType) =>
    '_${objectType.capitalize()}Adapter';

extension ObjectPropertyConvX on ObjectProperty {
  String toIsar(String input, ObjectInfo oi) {
    if (converter != null) {
      return '${getAdapterName(oi.dartName)}._${converter}.toIsar($input)';
    } else {
      return input;
    }
  }

  String fromIsar(String input, ObjectInfo oi) {
    if (converter != null) {
      return '${getAdapterName(oi.dartName)}._${converter}.fromIsar($input)';
    } else {
      return input;
    }
  }
}
