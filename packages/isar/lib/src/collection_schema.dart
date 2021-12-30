part of isar;

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
    required this.getId,
    required this.version,
  }) : assert(generatorVersion == version,
            'Incompatible generated code. Please rerun code generation using the latest generator.');

  IsarCollection<OBJ> toNativeCollection(
      {required IsarImpl isar,
      required Pointer<NativeType> ptr,
      required List<int> propertyOffsets}) {
    return IsarCollectionImpl(
      isar: isar,
      adapter: adapter,
      ptr: ptr,
      idName: idName,
      propertyOffsets: propertyOffsets,
      propertyIds: propertyIds,
      indexIds: indexIds,
      indexTypes: indexTypes,
      linkIds: linkIds,
      backlinkIds: backlinkIds,
      getId: getId,
    );
  }
}

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
  floatListHash,
  longListHash,
  doubleListHash,
  stringListHash,
  stringListHashCIS,
}
