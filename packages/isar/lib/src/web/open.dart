// ignore_for_file: public_member_api_docs, invalid_use_of_protected_member

import 'dart:html';
//import 'dart:js_util';

import 'package:isar/isar.dart';
/*import 'package:isar/src/common/schemas.dart';

import 'package:isar/src/web/bindings.dart';
import 'package:isar/src/web/isar_collection_impl.dart';
import 'package:isar/src/web/isar_impl.dart';*/
import 'package:isar/src/web/isar_web.dart';
import 'package:meta/meta.dart';

bool _loaded = false;
Future<void> initializeIsarWeb([String? jsUrl]) async {
  if (_loaded) {
    return;
  }
  _loaded = true;

  final script = ScriptElement();
  script.type = 'text/javascript';
  // ignore: unsafe_html
  script.src = 'https://unpkg.com/isar@${Isar.version}/dist/index.js';
  script.async = true;
  document.head!.append(script);
  await script.onLoad.first.timeout(
    const Duration(seconds: 30),
    onTimeout: () {
      throw IsarError('Failed to load Isar');
    },
  );
}

@visibleForTesting
void doNotInitializeIsarWeb() {
  _loaded = true;
}

Future<Isar> openIsar({
  required List<CollectionSchema<dynamic>> schemas,
  String? directory,
  required String name,
  required int maxSizeMiB,
  required bool relaxedDurability,
  CompactCondition? compactOnLaunch,
}) async {
  throw IsarError('Please use Isar 2.5.0 if you need web support. '
      'A 3.x version with web support will be released soon.');
  /*await initializeIsarWeb();
  final schemasJson = getSchemas(schemas).map((e) => e.toJson());
  final schemasJs = jsify(schemasJson.toList()) as List<dynamic>;
  final instance = await openIsarJs(name, schemasJs, relaxedDurability)
      .wait<IsarInstanceJs>();
  final isar = IsarImpl(name, instance);
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

  isar.attachCollections(cols);
  return isar;*/
}

Isar openIsarSync({
  required List<CollectionSchema<dynamic>> schemas,
  String? directory,
  required String name,
  required int maxSizeMiB,
  required bool relaxedDurability,
  CompactCondition? compactOnLaunch,
}) =>
    unsupportedOnWeb();
