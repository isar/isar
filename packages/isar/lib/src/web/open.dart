// ignore_for_file: public_member_api_docs

import 'dart:convert';
import 'dart:html';
import 'dart:js_util';

import 'package:isar/isar.dart';
import 'package:isar/src/version.dart';

import 'package:isar/src/web/bindings.dart';
import 'package:isar/src/web/isar_collection_impl.dart';
import 'package:isar/src/web/isar_impl.dart';

bool _loaded = false;
Future<void> initializeIsarWeb() async {
  if (_loaded) {
    return;
  }
  _loaded = true;

  final script = ScriptElement();
  script.type = 'text/javascript';
  // ignore: unsafe_html
  script.src = 'https://unpkg.com/isar@$isarWebVersion/dist/index.js';
  script.async = true;
  document.head!.append(script);
  await script.onLoad.first.timeout(
    const Duration(seconds: 30),
    onTimeout: () {
      throw IsarError('Failed to load Isar');
    },
  );
}

Future<Isar> openIsar({
  required String name,
  required bool relaxedDurability,
  required List<CollectionSchema<dynamic>> schemas,
}) async {
  await initializeIsarWeb();
  final schemaStr = '[${schemas.map((e) => e.schema).join(',')}]';

  final schemasJson = schemas.map((e) {
    final json = jsonDecode(e.schema) as Map<String, dynamic>;
    json['idName'] = e.idName;
    return json;
  });
  final schemasJs = jsify(schemasJson) as List<dynamic>;
  final instance = await openIsarJs(name, schemasJs, relaxedDurability)
      .wait<IsarInstanceJs>();
  final isar = IsarImpl(name, schemaStr, instance);
  final cols = <Type, IsarCollection<dynamic>>{};
  for (final schema in schemas) {
    final col = instance.getCollection(schema.name);
    schema.toCollection(<OBJ>() {
      schema as CollectionSchema<OBJ>;
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
