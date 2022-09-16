import 'package:isar/isar.dart';

extension CollectionSchemaX on CollectionSchema<dynamic> {
  PropertySchema propertyOrId(String name) {
    if (name == idName) {
      return PropertySchema(id: 0, name: name, type: IsarType.long);
    } else {
      return property(name);
    }
  }

  List<PropertySchema> get idAndProperties => [
        PropertySchema(id: 0, name: idName, type: IsarType.long),
        ...properties.values,
      ];
}
