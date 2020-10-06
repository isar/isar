import 'package:isar_generator/src/object_info.dart';

import 'package:dartx/dartx.dart';

String getCollectionVar(String objectType) =>
    '_${objectType.decapitalize()}Collection';
