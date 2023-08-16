part of isar;

class IsarSchema {
  const IsarSchema({
    required this.name,
    this.idName,
    required this.embedded,
    required this.properties,
    required this.indexes,
  });

  factory IsarSchema.fromJson(Map<String, dynamic> json) {
    return IsarSchema(
      name: json['name'] as String,
      idName: json['idName'] as String?,
      embedded: json['embedded'] as bool,
      properties: (json['properties'] as List<dynamic>)
          .map((e) => IsarPropertySchema.fromJson(e as Map<String, dynamic>))
          .toList(),
      indexes: (json['indexes'] as List<dynamic>)
          .map((e) => IsarIndexSchema.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String name;
  final String? idName;
  final bool embedded;
  final List<IsarPropertySchema> properties;
  final List<IsarIndexSchema> indexes;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'idName': idName,
      'embedded': embedded,
      'properties': properties.map((e) => e.toJson()).toList(),
      'indexes': indexes.map((e) => e.toJson()).toList(),
    };
  }

  int getPropertyIndex(String property) {
    for (var i = 0; i < properties.length; i++) {
      if (properties[i].name == property) {
        return i + 1;
      }
    }
    if (idName == property) {
      return 0;
    }
    throw ArgumentError('Property $property not found in schema $name');
  }

  IsarPropertySchema getPropertyByIndex(int index) {
    if (index == 0) {
      return IsarPropertySchema(
        name: idName!,
        type: IsarType.long,
      );
    } else {
      return properties[index - 1];
    }
  }
}

class IsarPropertySchema {
  const IsarPropertySchema({
    required this.name,
    required this.type,
    this.target,
    this.enumMap,
  });

  factory IsarPropertySchema.fromJson(Map<String, dynamic> json) {
    return IsarPropertySchema(
      name: json['name'] as String,
      type: IsarType.values.firstWhere(
        (e) => e.coreName == json['type'] as String,
      ),
      target: json['target'] as String?,
      enumMap: json['enumMap'] as Map<String, dynamic>?,
    );
  }

  final String name;
  final IsarType type;
  final String? target;
  final Map<String, dynamic>? enumMap;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.coreName,
      if (target != null) 'target': target,
      if (enumMap != null) 'enumMap': enumMap,
    };
  }
}

class IsarIndexSchema {
  const IsarIndexSchema({
    required this.name,
    required this.properties,
    required this.unique,
    required this.hash,
  });

  factory IsarIndexSchema.fromJson(Map<String, dynamic> json) {
    return IsarIndexSchema(
      name: json['name'] as String,
      properties: (json['properties'] as List).cast(),
      unique: json['unique'] as bool,
      hash: json['hash'] as bool,
    );
  }

  final String name;
  final List<String> properties;
  final bool unique;
  final bool hash;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'properties': properties,
      'unique': unique,
      'hash': hash,
    };
  }
}

enum IsarType {
  bool('Bool'),
  byte('Byte'),
  int('Int'),
  float('Float'),
  long('Long'),
  double('Double'),
  dateTime('DateTime'),
  string('String'),
  object('Object'),
  json('Json'),
  boolList('BoolList'),
  byteList('ByteList'),
  intList('IntList'),
  floatList('FloatList'),
  longList('LongList'),
  doubleList('DoubleList'),
  dateTimeList('DateTimeList'),
  stringList('StringList'),
  objectList('ObjectList');

  const IsarType(this.coreName);

  final String coreName;
}

extension IsarTypeX on IsarType {
  bool get isBool => this == IsarType.bool || this == IsarType.boolList;

  bool get isFloat =>
      this == IsarType.float ||
      this == IsarType.floatList ||
      this == IsarType.double ||
      this == IsarType.doubleList;

  bool get isInt =>
      this == IsarType.int ||
      this == IsarType.int ||
      this == IsarType.long ||
      this == IsarType.longList;

  bool get isNum => isFloat || isInt;

  bool get isDate => this == IsarType.dateTime || this == IsarType.dateTimeList;

  bool get isString => this == IsarType.string || this == IsarType.stringList;

  bool get isObject => this == IsarType.object || this == IsarType.objectList;

  bool get isList => scalarType != this;

  /// @nodoc
  IsarType get scalarType {
    switch (this) {
      case IsarType.boolList:
        return IsarType.bool;
      case IsarType.byteList:
        return IsarType.byte;
      case IsarType.intList:
        return IsarType.int;
      case IsarType.floatList:
        return IsarType.float;
      case IsarType.longList:
        return IsarType.long;
      case IsarType.doubleList:
        return IsarType.double;
      case IsarType.dateTimeList:
        return IsarType.dateTime;
      case IsarType.stringList:
        return IsarType.string;
      case IsarType.objectList:
        return IsarType.object;
      // ignore: no_default_cases
      default:
        return this;
    }
  }

  /// @nodoc
  IsarType get listType {
    switch (this) {
      case IsarType.bool:
        return IsarType.boolList;
      case IsarType.byte:
        return IsarType.byteList;
      case IsarType.int:
        return IsarType.intList;
      case IsarType.float:
        return IsarType.floatList;
      case IsarType.long:
        return IsarType.longList;
      case IsarType.double:
        return IsarType.doubleList;
      case IsarType.dateTime:
        return IsarType.dateTimeList;
      case IsarType.string:
        return IsarType.stringList;
      case IsarType.object:
        return IsarType.objectList;
      // ignore: no_default_cases
      default:
        return this;
    }
  }
}
