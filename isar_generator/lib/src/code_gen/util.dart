import 'package:dartx/dartx.dart';

String getCollectionVar(String objectType) =>
    '_${objectType.decapitalize()}Collection';
