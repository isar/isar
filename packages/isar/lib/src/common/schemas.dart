import 'package:isar/isar.dart';

/// @nodoc
List<Schema<dynamic>> getSchemas(
  List<CollectionSchema<dynamic>> collectionSchemas,
) {
  final schemas = <Schema<dynamic>>{};
  for (final collectionSchema in collectionSchemas) {
    schemas.add(collectionSchema);
    schemas.addAll(collectionSchema.embeddedSchemas.values);
  }
  return schemas.toList();
}
