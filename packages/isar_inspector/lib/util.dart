import 'package:isar/isar.dart';

extension CollectionInfoX on IsarSchema {
  int propertyIndex(String name) {
    if (name == idName) {
      return 0;
    } else {
      return properties.indexWhere((p) => p.name == name) + 1;
    }
  }

  List<IsarPropertySchema> get idAndProperties => [
        if (!this.embedded && !properties.any((e) => e.name == idName))
          IsarPropertySchema(name: idName!, type: IsarType.long),
        ...properties,
      ];
}
