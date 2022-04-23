part of isar;

/// @nodoc
@protected
typedef AdapterAlloc = IsarBytePointer Function(int size);

/// @nodoc
@protected
typedef SerializeNative<T> = void Function(
  IsarCollection<T> collection,
  IsarRawObject rawObj,
  T object,
  int staticSize,
  List<int> offsets,
  AdapterAlloc alloc,
);

/// @nodoc
@protected
typedef DeserializeNative<T> = T Function(
  IsarCollection<T> collection,
  int id,
  IsarBinaryReader reader,
  List<int> offsets,
);

/// @nodoc
@protected
typedef DeserializePropNative = dynamic Function(
  int id,
  IsarBinaryReader reader,
  int propertyIndex,
  int offset,
);

/// @nodoc
@protected
typedef SerializeWeb<T> = dynamic Function(
  IsarCollection<T> collection,
  T object,
);

/// @nodoc
@protected
typedef DeserializeWeb<T> = T Function(
  IsarCollection<T> collection,
  dynamic jsObj,
);

/// @nodoc
@protected
typedef DeserializePropWeb = dynamic Function(
  Object jsObj,
  String propertyName,
);

/// @nodoc
@protected
class CollectionSchema<OBJ> {
  static const generatorVersion = 3;

  final String name;
  final String schema;

  final String idName;
  final Map<String, int> propertyIds;
  final Set<String> listProperties;
  final Map<String, int> indexIds;
  final Map<String, List<IndexValueType>> indexValueTypes;
  final Map<String, int> linkIds;
  final Map<String, String> backlinkLinkNames;

  final int? Function(OBJ object) getId;
  final void Function(OBJ object, int id)? setId;

  final List<IsarLinkBase> Function(OBJ object) getLinks;
  final void Function(IsarCollection col, int id, OBJ object) attachLinks;

  final SerializeNative<OBJ> serializeNative;
  final DeserializeNative<OBJ> deserializeNative;
  final DeserializePropNative deserializePropNative;

  final SerializeWeb<OBJ> serializeWeb;
  final DeserializeWeb<OBJ> deserializeWeb;
  final DeserializePropWeb deserializePropWeb;

  final int version;

  const CollectionSchema({
    required this.name,
    required this.schema,
    required this.idName,
    required this.propertyIds,
    required this.listProperties,
    required this.indexIds,
    required this.indexValueTypes,
    required this.linkIds,
    required this.backlinkLinkNames,
    required this.getLinks,
    required this.attachLinks,
    required this.getId,
    this.setId,
    required this.serializeNative,
    required this.deserializeNative,
    required this.deserializePropNative,
    required this.serializeWeb,
    required this.deserializeWeb,
    required this.deserializePropWeb,
    required this.version,
  }) : assert(generatorVersion == version,
            'Incompatible generated code. Please re-run code generation using the latest generator.');

  void toCollection(void Function<OBJ>() callback) => callback<OBJ>();

  bool get hasLinks => linkIds.isNotEmpty;

  @pragma('vm:prefer-inline')
  int propertyIdOrErr(String propertyName) {
    final propertyId = propertyIds[propertyName];
    if (propertyId != null) {
      return propertyId;
    } else {
      throw IsarError('Unknown propery "$propertyName"');
    }
  }

  @pragma('vm:prefer-inline')
  int indexIdOrErr(String indexName) {
    final indexId = indexIds[indexName];
    if (indexId != null) {
      return indexId;
    } else {
      throw IsarError('Unknown index "$indexName"');
    }
  }

  @pragma('vm:prefer-inline')
  List<IndexValueType> indexValueTypeOrErr(String indexName) {
    final indexValueType = indexValueTypes[indexName];
    if (indexValueType != null) {
      return indexValueType;
    } else {
      throw IsarError('Unknown index "$indexName"');
    }
  }

  @pragma('vm:prefer-inline')
  int linkIdOrErr(String linkName) {
    final linkId = linkIds[linkName];
    if (linkId != null) {
      return linkId;
    } else {
      throw IsarError('Unknown link "$linkId"');
    }
  }
}

/// @nodoc
@protected
enum IndexValueType {
  bool,
  int,
  float,
  long,
  double,
  string, // Case-sensitive
  stringCIS, // Case-insensitive
  stringHash, // Case-sensitive, hashed
  stringHashCIS, // Case-insensitive, hashed
  bytesHash,
  boolListHash,
  intListHash,
  longListHash,
  stringListHash, // Case-sensitive, hashed
  stringListHashCIS, // Case-insensitive, hashed
}
