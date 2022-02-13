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
  script.src =
      'http://127.0.0.1:8080/dist/index.js'; //'https://unpkg.com/isar@$isarWebVersion/dist/index.js';
  script.async = true;
  assert(document.head != null);
  document.head!.append(script);
  await script.onLoad.first.timeout(Duration(seconds: 30), onTimeout: () {
    throw IsarError('Failed to load Isar');
  });
}

Future<Isar> openIsar({
  required String directory,
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
  final collections = <String, IsarCollection>{};
  for (var schema in schemas) {
    final col = instance.getCollection(schema.name);
    collections[schema.name] = schema.toCollection(<OBJ>() {
      schema as CollectionSchema<OBJ>;
      final isComposite =
          schema.indexTypes.map((name, e) => MapEntry(name, e.length != 1));
      return IsarCollectionImpl<OBJ>(
        isar: isar,
        col: col,
        adapter: schema.webAdapter,
        listProperties: schema.listProperties,
        isCompositeIndex: isComposite,
        idName: schema.idName,
        getId: schema.getId,
        setId: schema.setId,
        getLinks: schema.getLinks,
      );
    });
  }

  // ignore: invalid_use_of_protected_member
  isar.attachCollections(collections);
  return isar;
}
