part of isar;

/// @nodoc
@protected
class CollectionSchema<OBJ> {
  static const generatorVersion = 0;

  final String name;
  final String schema;
  final IsarTypeAdapter<OBJ> adapter;
  final String idName;
  final Map<String, int> propertyIds;
  final Map<String, int> indexIds;
  final Map<String, List<NativeIndexType>> indexTypes;
  final Map<String, int> linkIds;
  final Map<String, int> backlinkIds;
  final List<String> linkedCollections;
  final int? Function(OBJ) getId;
  final void Function(OBJ, int)? setId;
  final List<IsarLinkBase> Function(OBJ) getLinks;
  final int version;

  const CollectionSchema({
    required this.name,
    required this.schema,
    required this.adapter,
    required this.idName,
    required this.propertyIds,
    required this.indexIds,
    required this.indexTypes,
    required this.linkIds,
    required this.backlinkIds,
    required this.linkedCollections,
    required this.getLinks,
    required this.getId,
    required this.setId,
    required this.version,
  }) : assert(generatorVersion == version,
            'Incompatible generated code. Please rerun code generation using the latest generator.');

  IsarCollection<OBJ> toNativeCollection(
      {required IsarImpl isar,
      required Pointer<NativeType> ptr,
      required List<int> offsets}) {
    return IsarCollectionImpl(
      isar: isar,
      adapter: adapter,
      ptr: ptr,
      idName: idName,
      offsets: offsets,
      propertyIds: propertyIds,
      indexIds: indexIds,
      indexTypes: indexTypes,
      linkIds: linkIds,
      backlinkIds: backlinkIds,
      getLinks: getLinks,
      getId: getId,
      setId: setId,
    );
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
