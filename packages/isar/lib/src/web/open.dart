import 'dart:convert';
import 'dart:html';
import 'dart:js_util';

import 'package:isar/isar.dart';

import 'bindings.dart';
import 'isar_collection_impl.dart';
import 'isar_impl.dart';

var _loaded = false;
Future<void> initializeIsarWeb() async {
  if (_loaded) return;
  _loaded = true;

  ScriptElement script = ScriptElement();
  script.type = 'text/javascript';
  script.src = 'https://unpkg.com/isar@$isarWebVersion/dist/index.js';
  script.async = true;
  assert(document.head != null);
  document.head!.append(script);
  await script.onLoad.first.timeout(Duration(seconds: 30), onTimeout: () {
    throw IsarError('Failed to load Isar');
  });
}

Future<Isar> openIsar({
  required String name,
  required bool relaxedDurability,
  required List<CollectionSchema> schemas,
}) async {
  await initializeIsarWeb();
  final schemaStr = '[' + schemas.map((e) => e.schema).join(',') + ']';

  final schemasJson = schemas.map((e) {
    final json = jsonDecode(e.schema);
    json['idName'] = e.idName;
    return json;
  });
  final schemasJs = jsify(schemasJson);
  final IsarInstanceJs instance =
      await openIsarJs(name, schemasJs, relaxedDurability).wait();
  final isar = IsarImpl(name, schemaStr, instance);
  final cols = <Type, IsarCollection>{};
  for (var schema in schemas) {
    final col = instance.getCollection(schema.name);
    schema.toCollection(<OBJ>() {
      schema as CollectionSchema<OBJ>;
      final compositeIndexes = <String>{};
      for (var indexName in schema.indexValueTypes.keys) {
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
