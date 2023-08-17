part of isar;

/// The schema of a collection in Isar.
///
/// This class represents the structure of a collection. This includes the
/// collection name, the properties and indexes.
class IsarSchema {
  /// @nodoc
  const IsarSchema({
    required this.name,
    this.idName,
    required this.embedded,
    required this.properties,
    required this.indexes,
  });

  /// @nodoc
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

  /// The name of the collection.
  final String name;

  /// The name of the id property. Only String id properties are defined
  /// in [properties].
  final String? idName;

  /// Whether this collection is embedded in another object.
  final bool embedded;

  /// The properties of this collection.
  final List<IsarPropertySchema> properties;

  /// The indexes of this collection.
  final List<IsarIndexSchema> indexes;

  /// @nodoc
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'idName': idName,
      'embedded': embedded,
      'properties': properties.map((e) => e.toJson()).toList(),
      'indexes': indexes.map((e) => e.toJson()).toList(),
    };
  }

  /// Get the index of a property in this schema.
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

  /// Get the property schema by its index.
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

/// The schema of a property in Isar.
class IsarPropertySchema {
  /// @nodoc
  const IsarPropertySchema({
    required this.name,
    required this.type,
    this.target,
    this.enumMap,
  });

  /// @nodoc
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

  /// The name of the property.
  final String name;

  /// The type of the property.
  final IsarType type;

  /// If this property contains object(s), this is the name of the embedded
  /// collection.
  final String? target;

  /// If this property is an enum, this map contains the enum values.
  final Map<String, dynamic>? enumMap;

  /// @nodoc
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.coreName,
      if (target != null) 'target': target,
      if (enumMap != null) 'enumMap': enumMap,
    };
  }
}

/// The schema of an index in Isar.
class IsarIndexSchema {
  /// @nodoc
  const IsarIndexSchema({
    required this.name,
    required this.properties,
    required this.unique,
    required this.hash,
  });

  /// @nodoc
  factory IsarIndexSchema.fromJson(Map<String, dynamic> json) {
    return IsarIndexSchema(
      name: json['name'] as String,
      properties: (json['properties'] as List).cast(),
      unique: json['unique'] as bool,
      hash: json['hash'] as bool,
    );
  }

  /// The name of the index.
  final String name;

  /// The properties of the index.
  final List<String> properties;

  /// Whether this index is unique.
  final bool unique;

  /// Whether this index should be hashed.
  final bool hash;

  /// @nodoc
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'properties': properties,
      'unique': unique,
      'hash': hash,
    };
  }
}

/// Supported Isar property types.
enum IsarType {
  /// boolean (1 byte)
  bool('Bool'),

  /// unsigned 8 bit integer (1 byte)
  byte('Byte'),

  /// signed 32 bit integer (4 bytes)
  int('Int'),

  /// 32 bit floating point (4 bytes)
  float('Float'),

  /// signed 64 bit integer (8 bytes)
  long('Long'),

  /// 64 bit floating point (8 bytes)
  double('Double'),

  /// date and time stored in UTC (8 bytes)
  dateTime('DateTime'),

  /// string (6 + length bytes)
  string('String'),

  /// embedded object (6 + size bytes)
  object('Object'),

  /// json (6 + length bytes)
  json('Json'),

  /// list of booleans (6 + length bytes)
  boolList('BoolList'),

  /// list of unsigned 8 bit integers (6 + length bytes)
  byteList('ByteList'),

  /// list of signed 32 bit integers (6 + length * 4 bytes)
  intList('IntList'),

  /// list of 32 bit floating points (6 + length * 4 bytes)
  floatList('FloatList'),

  /// list of signed 64 bit integers (6 + length * 8 bytes)
  longList('LongList'),

  /// list of 64 bit floating points (6 + length * 8 bytes)
  doubleList('DoubleList'),

  /// list of dates and times stored in UTC (6 + length * 8 bytes)
  dateTimeList('DateTimeList'),

  /// list of strings (6 + length * (6 + length) bytes)
  stringList('StringList'),

  /// list of embedded objects (6 + length * (6 + size) bytes)
  objectList('ObjectList');

  const IsarType(this.coreName);

  /// @nodoc
  final String coreName;
}

/// @nodoc
extension IsarTypeX on IsarType {
  /// @nodoc
  bool get isBool => this == IsarType.bool || this == IsarType.boolList;

  /// @nodoc
  bool get isFloat =>
      this == IsarType.float ||
      this == IsarType.floatList ||
      this == IsarType.double ||
      this == IsarType.doubleList;

  /// @nodoc
  bool get isInt =>
      this == IsarType.int ||
      this == IsarType.int ||
      this == IsarType.long ||
      this == IsarType.longList;

  /// @nodoc
  bool get isNum => isFloat || isInt;

  /// @nodoc
  bool get isDate => this == IsarType.dateTime || this == IsarType.dateTimeList;

  /// @nodoc
  bool get isString => this == IsarType.string || this == IsarType.stringList;

  /// @nodoc
  bool get isObject => this == IsarType.object || this == IsarType.objectList;

  /// @nodoc
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
