part of isar;

/// A single propery of a collection or embedded object.
class PropertySchema {
  /// @nodoc
  @protected
  const PropertySchema({
    required this.id,
    required this.name,
    required this.type,
    this.target,
  });

  /// Hashed name
  final int id;

  /// Name of the property
  final String name;

  /// Isar type of the property
  final IsarType type;

  /// For embedde objects: Name of the target schema
  final String? target;

  /// @nodoc
  @protected
  Map<String, dynamic> toSchemaJson() {
    return {
      'name': name,
      'type': type.schemaName,
      if (target != null) 'target': target,
    };
  }
}

/// Supported Isar types
enum IsarType {
  /// 64-bit singed id
  id('Id'),

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
  dateTime('Long'),

  /// Enum
  enumeration('Byte'),

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
  dateTimeList('LongList'),

  /// Enum list
  enumerationList('ByteList'),

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
}
