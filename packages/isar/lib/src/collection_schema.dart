part of isar;

/// @nodoc
@protected
class CollectionSchema<OBJ> {
  static const generatorVersion = 2;

  final String name;
  final String schema;
  final IsarNativeTypeAdapter<OBJ> nativeAdapter;
  final IsarWebTypeAdapter<OBJ> webAdapter;
  final String idName;
  final Map<String, int> propertyIds;
  final Set<String> listProperties;
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
    required this.nativeAdapter,
    required this.webAdapter,
    required this.idName,
    required this.propertyIds,
    required this.listProperties,
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
            'Incompatible generated code. Please re-run code generation using the latest generator.');

  IsarCollection<OBJ> toCollection(
          IsarCollection<OBJ> Function<OBJ>() callback) =>
      callback();
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
