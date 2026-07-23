import 'package:isar/isar.dart';
import 'package:isar/isar_memory.dart';
import 'package:test/test.dart';

class MemoryObject {
  MemoryObject(this.name, {this.id = Isar.autoIncrement});

  int id;
  String name;
}

const memoryObjectSchema = CollectionSchema<MemoryObject>(
  id: 930001,
  name: 'MemoryObject',
  idName: 'id',
  properties: {
    'name': PropertySchema(id: 0, name: 'name', type: IsarType.string),
  },
  indexes: {
    'name': IndexSchema(
      id: 0,
      name: 'name',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: 'name',
          type: IndexType.value,
          caseSensitive: true,
        ),
      ],
    ),
  },
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
  MemoryObject object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) =>
    object.name.length;

void _serialize(
  MemoryObject object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.name);
}

MemoryObject _deserialize(
  int id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) =>
    MemoryObject(reader.readString(offsets[0]), id: id);

dynamic _deserializeProp(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) =>
    reader.readString(offset);

int _getId(MemoryObject object) => object.id;
List<IsarLinkBase<dynamic>> _getLinks(MemoryObject object) => const [];
void _attach(IsarCollection<MemoryObject> col, int id, MemoryObject object) {
  object.id = id;
}

void main() {
  tearDown(() async {
    await Isar.getInstance()?.close(deleteFromDisk: true);
  });

  test('supports sync CRUD, indexes, and rollback', () {
    final isar = IsarMemory.openSync([memoryObjectSchema]);
    final objects = isar.collection<MemoryObject>();

    final first = MemoryObject('first');
    isar.writeTxnSync(() => objects.putSync(first));
    expect(first.id, 1);
    expect(objects.getSync(first.id)?.name, 'first');
    expect(objects.getByIndexSync('name', ['first'])?.id, first.id);

    expect(
      () => isar.writeTxnSync(() {
        objects.putSync(MemoryObject('rolled back'));
        throw StateError('rollback');
      }),
      throwsStateError,
    );
    expect(objects.where().countSync(), 1);
  });

  test('supports async CRUD and exact delete counts', () async {
    final isar = await IsarMemory.open(
      [memoryObjectSchema],
      name: 'async-memory',
    );
    final objects = isar.collection<MemoryObject>();
    await isar.writeTxn(() => objects.putAll([
          MemoryObject('one'),
          MemoryObject('two'),
        ]));
    expect(await objects.where().count(), 2);
    expect(await isar.writeTxn(() => objects.deleteAll([1, 1, 99])), 1);
    expect(await objects.where().count(), 1);
  });

  test('serializes concurrent async writes', () async {
    final isar = await IsarMemory.open(
      [memoryObjectSchema],
      name: 'write-queue',
    );
    final objects = isar.collection<MemoryObject>();
    await Future.wait([
      isar.writeTxn(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await objects.put(MemoryObject('first queued'));
      }),
      isar.writeTxn(() => objects.put(MemoryObject('second queued'))),
    ]);
    expect(await objects.where().count(), 2);
  });

  test('rejects nested transactions and honors silent watchers', () async {
    final isar = await IsarMemory.open(
      [memoryObjectSchema],
      name: 'transaction-semantics',
    );
    final objects = isar.collection<MemoryObject>();
    expect(
      () => isar.writeTxnSync(() => isar.txnSync(() {})),
      throwsA(isA<IsarError>()),
    );

    var events = 0;
    final subscription = objects.watchLazy().listen((_) => events++);
    await isar.writeTxn(
      () => objects.put(MemoryObject('silent')),
      silent: true,
    );
    await Future<void>.delayed(Duration.zero);
    expect(events, 0);
    await isar.writeTxn(() => objects.put(MemoryObject('watched')));
    await Future<void>.delayed(Duration.zero);
    expect(events, 1);
    await subscription.cancel();
  });
}
