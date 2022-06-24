import 'dart:convert';
import 'dart:html';
import 'dart:js_util';

import '../../isar.dart';
import '../version.dart';

import 'bindings.dart';
import 'isar_collection_impl.dart';
import 'isar_impl.dart';

bool _loaded = false;
Future<void> initializeIsarWeb() async {
  if (_loaded) {
    return;
  }
  _loaded = true;

  final ScriptElement script = ScriptElement();
  script.type = 'text/javascript';
  // ignore: unsafe_html
  script.src = 'https://unpkg.com/isar@$isarWebVersion/dist/index.js';
  script.async = true;
  assert(document.head != null);
  document.head!.append(script);
  await script.onLoad.first.timeout(const Duration(seconds: 30), onTimeout: () {
    // ignore: only_throw_errors
    throw IsarError('Failed to load Isar');
  });
}

Future<Isar> openIsar({
  required String name,
  required bool relaxedDurability,
  required List<CollectionSchema<dynamic>> schemas,
}) async {
  await initializeIsarWeb();
  final String schemaStr =
      '[${schemas.map((CollectionSchema e) => e.schema).join(',')}]';

  final Iterable schemasJson = schemas.map((CollectionSchema e) {
    final json = jsonDecode(e.schema);
    json['idName'] = e.idName;
    return json;
  });
  final List schemasJs = jsify(schemasJson) as List<dynamic>;
  final IsarInstanceJs instance =
      await openIsarJs(name, schemasJs, relaxedDurability).wait();
  final IsarImpl isar = IsarImpl(name, schemaStr, instance);
  final Map<Type, IsarCollection> cols = <Type, IsarCollection<dynamic>>{};
  for (final CollectionSchema schema in schemas) {
    final IsarCollectionJs col = instance.getCollection(schema.name);
    schema.toCollection(<OBJ>() {
      schema as CollectionSchema<OBJ>;
      final Set<String> compositeIndexes = <String>{};
      for (final String indexName in schema.indexValueTypes.keys) {
        if (schema.indexValueTypes[indexName]!.length > 1) {
          compositeIndexes.add(indexName);
        }
      }
      cols[OBJ] = IsarCollectionImpl<OBJ>(
        isar: isar,
        native: col,
        schema: schema,
      );
    });
  }

  // ignore: invalid_use_of_protected_member
  isar.attachCollections(cols);
  return isar;
}
