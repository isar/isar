import 'package:isar_generator/src/object_info.dart';

import 'package:dartx/dartx.dart';

String getBankVar(String objectType) => '_${objectType.decapitalize()}Bank';
