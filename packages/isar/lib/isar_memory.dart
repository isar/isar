library isar_memory;

import 'package:isar/isar.dart';
import 'package:isar/src/dart_engine/engine.dart';

/// Opens disposable Isar databases backed entirely by Dart memory.
abstract final class IsarMemory {
  /// Opens an in-memory database asynchronously.
  static Future<Isar> open(
    List<CollectionSchema<dynamic>> schemas, {
    String name = Isar.defaultName,
  }) async =>
      openSync(schemas, name: name);

  /// Opens an in-memory database synchronously.
  static Isar openSync(
    List<CollectionSchema<dynamic>> schemas, {
    String name = Isar.defaultName,
  }) {
    _validate(name, schemas);
    return DartEngineIsar(name, schemas);
  }

  static void _validate(
    String name,
    List<CollectionSchema<dynamic>> schemas,
  ) {
    if (name.isEmpty || name.startsWith('_')) {
      throw IsarError('Instance names must not be empty or start with "_".');
    }
    if (Isar.getInstance(name) != null) {
      throw IsarError('Instance has already been opened.');
    }
    if (schemas.isEmpty) {
      throw IsarError('At least one collection needs to be opened.');
    }
    final names = schemas.map((schema) => schema.name).toSet();
    if (names.length != schemas.length) {
      throw IsarError('Duplicate collection schema.');
    }
    for (final schema in schemas) {
      for (final target in schema.links.values.map((link) => link.target)) {
        if (!names.contains(target)) {
          throw IsarError(
            'Collection ${schema.name} depends on missing collection $target.',
          );
        }
      }
    }
  }
}
