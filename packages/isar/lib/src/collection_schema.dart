// ignore_for_file: public_member_api_docs

part of isar;

/// @nodoc
@protected
class CollectionSchema<OBJ> {
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
    required this.dependencies,
    required this.getId,
    required this.getLinks,
    required this.attach,
    required this.serializeNative,
    required this.estimateSize,
    required this.deserializeNative,
    required this.deserializePropNative,
    required this.serializeWeb,
    required this.deserializeWeb,
    required this.deserializePropWeb,
    required this.version,
  }) : assert(
          generatorVersion == version,
          'Incompatible generated code. Please re-run code '
          'generation using the latest generator.',
        );
  static const int generatorVersion = 4;

  final String name;
  final String schema;

  final String idName;
  final Map<String, int> propertyIds;
  final Set<String> listProperties;
  final Map<String, int> indexIds;
  final Map<String, List<IndexValueType>> indexValueTypes;
  final Map<String, int> linkIds;
  final Map<String, String> backlinkLinkNames;
  final List<String> dependencies;

  final GetId<OBJ> getId;
  final GetLinks<OBJ> getLinks;
  final Attach<OBJ> attach;

  final EstimateSize<OBJ> estimateSize;
  final SerializeNative<OBJ> serializeNative;
  final DeserializeNative<OBJ> deserializeNative;
  final DeserializePropNative deserializePropNative;

  final SerializeWeb<OBJ> serializeWeb;
  final DeserializeWeb<OBJ> deserializeWeb;
  final DeserializePropWeb deserializePropWeb;

  final int version;

  void toCollection(void Function<OBJ>() callback) => callback<OBJ>();

  bool get hasLinks => linkIds.isNotEmpty;

  @pragma('vm:prefer-inline')
  int propertyIdOrErr(String propertyName) {
    final propertyId = propertyIds[propertyName];
    if (propertyId != null) {
      return propertyId;
    } else {
      throw IsarError('Unknown property "$propertyName"');
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
  byte,
  int,
  float,
  long,
  double,
  string, // Case-sensitive
  stringCIS, // Case-insensitive
  stringHash, // Case-sensitive, hashed
  stringHashCIS, // Case-insensitive, hashed
  boolListHash,
  byteListHash,
  intListHash,
  longListHash,
  stringListHash, // Case-sensitive, hashed
  stringListHashCIS, // Case-insensitive, hashed
}

/// @nodoc
@protected
typedef GetId<T> = int? Function(T object);

/// @nodoc
@protected
typedef GetLinks<T> = List<IsarLinkBase<dynamic>> Function(T object);

/// @nodoc
@protected
typedef Attach<T> = void Function(IsarCollection<T> col, int id, T object);

/// @nodoc
@protected
typedef EstimateSize<T> = int Function(
  T object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
);

/// @nodoc
@protected
typedef SerializeNative<T> = int Function(
  T object,
  IsarBinaryWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
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
typedef SerializeWeb<T> = Object Function(
  IsarCollection<T> collection,
  T object,
);

/// @nodoc
@protected
typedef DeserializeWeb<T> = T Function(
  IsarCollection<T> collection,
  Object jsObj,
);

/// @nodoc
@protected
typedef DeserializePropWeb = dynamic Function(
  Object jsObj,
  String propertyName,
);
