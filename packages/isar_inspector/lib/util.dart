import 'package:isar/isar.dart';

extension CollectionInfoX on IsarSchema {
  List<IsarPropertySchema> get idAndProperties {
    final props = [
      if (!this.embedded && !properties.any((e) => e.name == idName))
        IsarPropertySchema(name: idName!, type: IsarType.long),
      ...properties,
    ];
    props.sort((a, b) {
      if (a.name == idName) {
        return -1;
      } else if (b.name == idName) {
        return 1;
      } else {
        return a.name.compareTo(b.name);
      }
    });
    return props;
  }
}

extension TypeName on IsarType {
  String get typeName {
    switch (this) {
      case IsarType.bool:
        return 'bool';
      case IsarType.byte:
        return 'byte';
      case IsarType.int:
        return 'short';
      case IsarType.long:
        return 'int';
      case IsarType.float:
        return 'float';
      case IsarType.double:
        return 'double';
      case IsarType.dateTime:
        return 'DateTime';
      case IsarType.string:
        return 'String';
      case IsarType.object:
        return 'Object';
      case IsarType.json:
        return 'Json';
      case IsarType.boolList:
        return 'List<bool>';
      case IsarType.byteList:
        return 'List<byte>';
      case IsarType.intList:
        return 'List<short>';
      case IsarType.longList:
        return 'List<int>';
      case IsarType.floatList:
        return 'List<float>';
      case IsarType.doubleList:
        return 'List<double>';
      case IsarType.dateTimeList:
        return 'List<DateTime>';
      case IsarType.stringList:
        return 'List<String>';
      case IsarType.objectList:
        return 'List<Object>';
    }
  }
}
