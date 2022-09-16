part of isar;

/// A single propery of a collection or embedded object.
class PropertySchema {
  /// @nodoc
  @protected
  const PropertySchema({
    required this.id,
    required this.name,
    required this.type,
    this.enumMap,
    this.target,
  });

  /// @nodoc
  @protected
  factory PropertySchema.fromJson(Map<String, dynamic> json) {
    return PropertySchema(
      id: -1,
      name: json['name'] as String,
      type: IsarType.values.firstWhere((e) => e.schemaName == json['type']),
      enumMap: json['enumMap'] as Map<String, dynamic>?,
      target: json['target'] as String?,
    );
  }

  /// Internal id of this property.
  final int id;

  /// Name of the property
  final String name;

  /// Isar type of the property
  final IsarType type;

  /// Maps enum names to database values
  final Map<String, dynamic>? enumMap;

  /// For embedded objects: Name of the target schema
  final String? target;

  /// @nodoc
  @protected
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
      'type': type.schemaName,
      if (target != null) 'target': target,
    };

    assert(() {
      if (enumMap != null) {
        json['enumMap'] = enumMap;
      }
      return true;
    }());

    return json;
  }
}

/// Supported Isar types
enum IsarType {
  /// Boolean
  bool('Bool'),

  /// 8-bit unsigned integer
  byte('Byte'),

  /// 32-bit singed integer
  int('Int'),

  /// 32-bit float
  float('Float'),

  /// 64-bit singed integer
  long('Long'),

  /// 64-bit float
  double('Double'),

  /// DateTime
  dateTime('DateTime'),

  /// String
  string('String'),

  /// Embedded object
  object('Object'),

  /// Boolean list
  boolList('BoolList'),

  /// 8-bit unsigned integer list
  byteList('ByteList'),

  /// 32-bit singed integer list
  intList('IntList'),

  /// 32-bit float list
  floatList('FloatList'),

  /// 64-bit singed integer list
  longList('LongList'),

  /// 64-bit float list
  doubleList('DoubleList'),

  /// DateTime list
  dateTimeList('DateTimeList'),

  /// String list
  stringList('StringList'),

  /// Embedded object list
  objectList('ObjectList');

  /// @nodoc
  const IsarType(this.schemaName);

  /// @nodoc
  final String schemaName;
}

/// @nodoc
extension IsarTypeX on IsarType {
  /// Whether this type represents a list
  bool get isList => index >= IsarType.boolList.index;

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
