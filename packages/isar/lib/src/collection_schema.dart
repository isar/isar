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

  final SerializeNative<OBJ> serializeNative;
  final DeserializeNative<OBJ> deserializeNative;
  final DeserializePropNative deserializePropNative;

  final SerializeWeb<OBJ> serializeWeb;
  final DeserializeWeb<OBJ> deserializeWeb;
  final DeserializePropWeb deserializePropWeb;

  final String idName;
  final Map<String, int> propertyIds;
  final Set<String> listProperties;
  final Map<String, int> indexIds;
  final Map<String, List<NativeIndexType>> indexTypes;
  final Map<String, int> linkIds;

  final Map<String, String> linkTargetCollections;
  final Map<String, String> backlinkSourceCollections;

  final int? Function(OBJ object) getId;
  final void Function(OBJ object, int id) setId;

  final List<IsarLinkBase> Function(OBJ object) getLinks;
  final List<IsarLinkBase> Function(Isar isar, int id, OBJ object) attachLinks;
  final int version;

  CollectionSchema({
    required this.name,
    required this.schema,
    required this.serializeNative,
    required this.deserializeNative,
    required this.deserializePropNative,
    required this.serializeWeb,
    required this.deserializeWeb,
    required this.deserializePropWeb,
    required this.idName,
    required this.propertyIds,
    required this.listProperties,
    required this.indexIds,
    required this.indexTypes,
    required this.linkIds,
    required this.linkTargetCollections,
    required this.backlinkSourceCollections,
    required this.getLinks,
    required this.attachLinks,
    required this.getId,
    required this.setId,
    required this.version,
  }) : assert(generatorVersion == version,
            'Incompatible generated code. Please re-run code generation using the latest generator.');

  void toCollection(void Function<OBJ>() callback) => callback();

  late final bool hasLinks =
      linkTargetCollections.isNotEmpty || backlinkSourceCollections.isNotEmpty;

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
  List<NativeIndexType> indexTypeOrErr(String indexName) {
    final indexType = indexTypes[indexName];
    if (indexType != null) {
      return indexType;
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

  @pragma('vm:prefer-inline')
  IsarCollection linkColOrErr(
      IsarCollection col, String linkName, bool source) {
    final linkTarget = linkTargetCollections[linkName];
    if (linkTarget != null) {
      if (source) {
        return col;
      } else {
        // ignore: invalid_use_of_protected_member
        return col.isar.getCollectionInternal(linkTarget)!;
      }
    } else {
      final backlinkSource = backlinkSourceCollections[linkName];
      if (backlinkSource != null) {
        if (source) {
          // ignore: invalid_use_of_protected_member
          return col.isar.getCollectionInternal(backlinkSource)!;
        } else {
          return col;
        }
      } else {
        throw IsarError('Unknown link "$linkName"');
      }
    }
  }
}

/// @nodoc
@protected
enum NativeIndexType {
  bool,
  int,
  float,
  long,
  double,
  string,
  stringCIS,
  stringHash,
  stringHashCIS,
  bytesHash,
  boolListHash,
  intListHash,
  longListHash,
  stringListHash,
  stringListHashCIS,
}
