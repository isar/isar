@TestOn('browser')
library;

import 'package:isar/isar.dart';
import 'package:test/test.dart';

class WebObject {
  WebObject(this.value, {this.id = Isar.autoIncrement});

  int id;
  String value;
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

WebObject _deserialize(
  int id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) =>
    WebObject(reader.readString(offsets[0]), id: id);

dynamic _deserializeProp(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) =>
    reader.readString(offset);

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
}
