@TestOn('browser')
library;

import 'package:isar/isar.dart';
import 'package:isar/src/web/indexeddb_open.dart' as indexeddb;
import 'package:test/test.dart';

class WebObject {
  WebObject(
    this.value, {
    this.id = Isar.autoIncrement,
    this.count = 0,
  });

  int id;
  String value;
  int count;
}

const webObjectSchema = CollectionSchema<WebObject>(
  id: 930002,
  name: 'WebObject',
  idName: 'id',
  properties: {
    'value': PropertySchema(id: 0, name: 'value', type: IsarType.string),
  },
  indexes: {},
  links: {},
  embeddedSchemas: {},
  estimateSize: _estimateSize,
  serialize: _serialize,
  deserialize: _deserialize,
  deserializeProp: _deserializeProp,
  getId: _getId,
  getLinks: _getLinks,
  attach: _attach,
  version: Isar.version,
);

const webObjectSchemaV2 = CollectionSchema<WebObject>(
  id: 930002,
  name: 'WebObject',
  idName: 'id',
  properties: {
    'value': PropertySchema(id: 0, name: 'value', type: IsarType.string),
    'count': PropertySchema(id: 1, name: 'count', type: IsarType.long),
  },
  indexes: {},
  links: {},
  embeddedSchemas: {},
  estimateSize: _estimateSize,
  serialize: _serializeV2,
  deserialize: _deserializeV2,
  deserializeProp: _deserializePropV2,
  getId: _getId,
  getLinks: _getLinks,
  attach: _attach,
  version: Isar.version,
);

int _estimateSize(
  WebObject object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) =>
    object.value.length;

void _serialize(
  WebObject object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.value);
}

void _serializeV2(
  WebObject object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer
    ..writeString(offsets[0], object.value)
    ..writeLong(offsets[1], object.count);
}

WebObject _deserialize(
  int id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) =>
    WebObject(reader.readString(offsets[0]), id: id);

WebObject _deserializeV2(
  int id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) =>
    WebObject(
      reader.readString(offsets[0]),
      id: id,
      count: reader.readLong(offsets[1]),
    );

dynamic _deserializeProp(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) =>
    reader.readString(offset);

dynamic _deserializePropV2(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) =>
    propertyId == 0 ? reader.readString(offset) : reader.readLong(offset);

int _getId(WebObject object) => object.id;
List<IsarLinkBase<dynamic>> _getLinks(WebObject object) => const [];
void _attach(IsarCollection<WebObject> col, int id, WebObject object) {
  object.id = id;
}

void main() {
  test('splits Unicode words without native code', () {
    expect(Isar.splitWords('Hello, 世界 123'), ['Hello', '世界', '123']);
  });

  test('persists committed state and rolls back failed transactions', () async {
    const name = 'indexeddb-reopen-test';
    var isar = await Isar.open([webObjectSchema], name: name);
    var objects = isar.collection<WebObject>();
    await isar.writeTxn(() => objects.clear());
    await isar.writeTxn(() => objects.put(WebObject('persisted')));
    await isar.close();

    isar = await Isar.open([webObjectSchema], name: name);
    objects = isar.collection<WebObject>();
    expect((await objects.where().findFirst())?.value, 'persisted');

    await expectLater(
      isar.writeTxn(() async {
        await objects.put(WebObject('rolled-back'));
        throw StateError('rollback');
      }),
      throwsStateError,
    );
    expect(await objects.where().count(), 1);
    await isar.close();
  });

  test('deletes IndexedDB when closing with deleteFromDisk', () async {
    const name = 'indexeddb-delete-test';
    var isar = await Isar.open([webObjectSchema], name: name);
    await isar.writeTxn(
      () => isar.collection<WebObject>().put(WebObject('temporary')),
    );
    await isar.close(deleteFromDisk: true);

    isar = await Isar.open([webObjectSchema], name: name);
    expect(await isar.collection<WebObject>().count(), 0);
    await isar.close(deleteFromDisk: true);
  });

  test('migrates compatible added properties with defaults', () async {
    const name = 'indexeddb-migration-test';
    var isar = await Isar.open([webObjectSchema], name: name);
    await isar.writeTxn(
      () => isar.collection<WebObject>().put(WebObject('old')),
    );
    await isar.close();

    isar = await Isar.open([webObjectSchemaV2], name: name);
    final object = await isar.collection<WebObject>().where().findFirst();
    expect(object?.value, 'old');
    expect(object?.count, 0);
    await isar.close(deleteFromDisk: true);
  });

  test('rejects a concurrent direct owner', () async {
    const name = 'indexeddb-owner-test';
    final first = await indexeddb.openIsar(
      schemas: [webObjectSchema],
      name: name,
      maxSizeMiB: 256,
      relaxedDurability: true,
    );
    await expectLater(
      indexeddb.openIsar(
        schemas: [webObjectSchema],
        name: name,
        maxSizeMiB: 256,
        relaxedDurability: true,
      ),
      throwsA(isA<IsarError>()),
    );
    await first.close(deleteFromDisk: true);
  });
}
