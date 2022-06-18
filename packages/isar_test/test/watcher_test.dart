import 'dart:async';

import 'package:isar/isar.dart';
import 'package:test/test.dart';

import 'util/common.dart';
import 'util/sync_async_helper.dart';

part 'watcher_test.g.dart';

@Collection()
class Value {
  Value(this.id, this.value);
  int? id;

  @Index(unique: true)
  String? value;

  @override
  // ignore: hash_and_equals, always_declare_return_types
  operator ==(Object other) =>
      other is Value && id == other.id && value == other.value;
}

class Listener<T> {
  Listener(Stream<T> stream) {
    subscription = stream.listen((event) {
      if (_completer != null) {
        _completer!.complete(event);
        _completer = null;
      } else {
        _unprocessed.add(event);
      }
    });
  }
  late StreamSubscription<void> subscription;
  final List<T> _unprocessed = <T>[];
  Completer<T>? _completer;

  Future<T> get next {
    if (_unprocessed.isEmpty) {
      expect(_completer, null);
      _completer = Completer<T>();
      return _completer!.future;
    } else {
      return Future.value(_unprocessed.removeAt(0));
    }
  }

  Future<void> done() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await subscription.cancel();
    expect(_completer, null);
    expect(_unprocessed, <dynamic>[]);
  }
}

void main() {
  testSyncAsync(tests);
}

void tests() {
  group('Watcher', () {
    late Isar isar;
    late IsarCollection<Value> col;

    late Value obj1;
    late Value obj2;
    late Value obj3;

    setUp(() async {
      isar = await openTempIsar([ValueSchema]);
      col = isar.values;

      obj1 = Value(1, 'Hello');
      obj2 = Value(2, 'Hi');
      obj3 = Value(3, 'Test');
    });

    tearDown(() async {
      await isar.close();
    });

    group('Collection', () {
      isarTest('.put()', () async {
        final Listener<void> listener = Listener(col.watchLazy());

        isar.tWriteTxn(() => col.tPut(obj1));
        await listener.next;

        isar.tWriteTxn(() => col.tPut(obj1));
        await listener.next;

        await listener.done();
      });

      isarTest('.putAll()', () async {
        final Listener<void> listener = Listener(col.watchLazy());

        isar.tWriteTxn(() => col.tPutAll([obj1, obj2]));
        await listener.next;

        isar.tWriteTxn(() => col.tPutAll([obj1]));
        await listener.next;

        await listener.done();
      });

      isarTest('.delete()', () async {
        await isar.tWriteTxn(() => col.tPutAll([obj1, obj2]));

        final Listener<void> listener = Listener(col.watchLazy());

        isar.tWriteTxn(() => col.tDelete(1));
        await listener.next;

        isar.tWriteTxn(() => col.tDelete(2));
        await listener.next;

        await listener.done();
      });

      isarTest('.deleteAll()', () async {
        await isar.tWriteTxn(() => col.tPutAll([obj1, obj2]));

        final Listener<void> listener = Listener(col.watchLazy());

        isar.tWriteTxn(() => col.tDeleteAll([1, 3]));
        await listener.next;

        isar.tWriteTxn(() => col.tDeleteAll([2]));
        await listener.next;

        await listener.done();
      });

      isarTest('.deleteBy()', () async {
        await isar.writeTxn(() => col.putAll([obj1, obj2]));

        final Listener<void> listener = Listener(col.watchLazy());

        isar.writeTxn(() => col.deleteByValue(obj1.value));
        await listener.next;

        isar.writeTxn(() => col.deleteByValue(obj2.value));
        await listener.next;

        await listener.done();
      });

      isarTest('.deleteAllBy()', () async {
        await isar.writeTxn(() => col.putAll([obj1, obj2]));

        final Listener<void> listener = Listener(col.watchLazy());

        isar.writeTxn(() => col.deleteAllByValue([obj1.value, 'something']));
        await listener.next;

        isar.writeTxn(() => col.deleteAllByValue([obj2.value]));
        await listener.next;

        await listener.done();
      });
    });

    group('Object', () {
      isarTest('.put()', () async {
        final Listener<void> listenerLazy = Listener(col.watchObjectLazy(1));
        final Listener<Value?> listener = Listener(col.watchObject(2));

        isar.tWriteTxn(() => col.tPut(obj1));
        await listenerLazy.next;

        isar.tWriteTxn(() => col.tPut(obj2));
        expect(await listener.next, obj2);

        await listenerLazy.done();
        await listener.done();
      });

      isarTest('.putAll()', () async {
        final Listener<void> listenerLazy = Listener(col.watchObjectLazy(1));
        final Listener<Value?> listener = Listener(col.watchObject(2));

        isar.tWriteTxn(() => col.tPutAll([obj1, obj3]));
        await listenerLazy.next;

        isar.tWriteTxn(() => col.tPutAll([obj1, obj2]));
        await listenerLazy.next;
        expect(await listener.next, obj2);

        await listenerLazy.done();
        await listener.done();
      });

      isarTest('.delete()', () async {
        await isar.tWriteTxn(() => col.tPutAll([obj1, obj2, obj3]));

        final Listener<void> listenerLazy = Listener(col.watchObjectLazy(1));
        final Listener<Value?> listener = Listener(col.watchObject(2));

        isar.tWriteTxn(() => col.tDelete(1));
        await listenerLazy.next;

        isar.tWriteTxn(() => col.tDelete(2));
        expect(await listener.next, null);

        await listenerLazy.done();
        await listener.done();
      });

      isarTest('.deleteAll()', () async {
        await isar.tWriteTxn(() => col.tPutAll([obj1, obj2, obj3]));

        final Listener<void> listenerLazy = Listener(col.watchObjectLazy(1));
        final Listener<Value?> listener = Listener(col.watchObject(2));

        isar.tWriteTxn(() => col.tDeleteAll([4, 1]));
        await listenerLazy.next;

        isar.tWriteTxn(() => col.tDeleteAll([2, 3]));
        expect(await listener.next, null);

        await listenerLazy.done();
        await listener.done();
      });

      isarTest('.deleteBy()', () async {
        await isar.writeTxn(() => col.putAll([obj1, obj2, obj3]));

        final Listener<void> listenerLazy = Listener(col.watchObjectLazy(1));
        final Listener<Value?> listener = Listener(col.watchObject(2));

        isar.writeTxn(() => col.deleteByValue(obj1.value));
        await listenerLazy.next;

        isar.writeTxn(() => col.deleteByValue(obj2.value));
        expect(await listener.next, null);

        await listenerLazy.done();
        await listener.done();
      });

      isarTest('.deleteAllBy()', () async {
        await isar.writeTxn(() => col.putAll([obj1, obj2, obj3]));

        final Listener<void> listenerLazy = Listener(col.watchObjectLazy(1));
        final Listener<Value?> listener = Listener(col.watchObject(2));

        isar.writeTxn(() => col.deleteAllByValue(['AAA', obj1.value]));
        await listenerLazy.next;

        isar.writeTxn(() => col.deleteAllByValue([obj2.value, obj3.value]));
        expect(await listener.next, null);

        await listenerLazy.done();
        await listener.done();
      });
    });

    group('Query', () {
      isarTest('.put()', () async {
        final Listener listenerLazy =
            Listener(col.where().valueEqualTo('Hello').watchLazy());
        final Listener listener =
            Listener(col.where().valueEqualTo('Hi').watch());

        isar.tWriteTxn(() => col.tPut(obj1));
        await listenerLazy.next;

        isar.tWriteTxn(() => col.tPut(obj2));
        expect(await listener.next, [obj2]);

        await listenerLazy.done();
        await listener.done();
      });

      isarTest('.putAll()', () async {
        final Listener listenerLazy =
            Listener(col.filter().valueContains('H').watchLazy());
        final Listener listener =
            Listener(col.filter().valueContains('H').watch());

        isar.tWriteTxn(() => col.tPutAll([obj1, obj2]));
        await listenerLazy.next;
        expect(await listener.next, [obj1, obj2]);

        await isar.tWriteTxn(() => col.tPutAll([obj3]));

        await listenerLazy.done();
        await listener.done();
      });

      isarTest('.delete()', () async {
        await isar.tWriteTxn(() => col.tPutAll([obj1, obj2, obj3]));

        final Listener listenerLazy =
            Listener(col.where().valueEqualTo('Hello').watchLazy());
        final Listener listener =
            Listener(col.where().valueEqualTo('Hi').watch());

        isar.tWriteTxn(() => col.tDelete(1));
        await listenerLazy.next;
        if (kIsWeb) {
          expect(await listener.next, [obj2]);
        }

        isar.tWriteTxn(() => col.tDelete(2));
        if (kIsWeb) {
          await listenerLazy.next;
        }
        expect(await listener.next, <dynamic>[]);

        await listenerLazy.done();
        await listener.done();
      });

      isarTest('.deleteAll()', () async {
        await isar.tWriteTxn(() => col.tPutAll([obj1, obj2, obj3]));

        final Listener listenerLazy =
            Listener(col.filter().valueContains('H').watchLazy());
        final Listener listener =
            Listener(col.filter().valueContains('H').watch());

        isar.tWriteTxn(() => col.tDeleteAll([1, 2]));
        await listenerLazy.next;
        expect(await listener.next, <dynamic>[]);

        await isar.tWriteTxn(() => col.tDeleteAll([3]));
        if (kIsWeb) {
          await listenerLazy.next;
          expect(await listener.next, <dynamic>[]);
        }

        await listenerLazy.done();
        await listener.done();
      });

      isarTest('.deleteBy()', () async {
        await isar.writeTxn(() => col.putAll([obj1, obj2, obj3]));

        final Listener listenerLazy =
            Listener(col.where().valueEqualTo('Hello').watchLazy());
        final Listener listener =
            Listener(col.where().valueEqualTo('Hi').watch());

        isar.writeTxn(() => col.deleteByValue(obj1.value));
        await listenerLazy.next;
        if (kIsWeb) {
          expect(await listener.next, [obj2]);
        }

        isar.writeTxn(() => col.deleteByValue(obj2.value));
        if (kIsWeb) {
          await listenerLazy.next;
        }
        expect(await listener.next, <dynamic>[]);

        await listenerLazy.done();
        await listener.done();
      });

      isarTest('.deleteAllByValue()', () async {
        await isar.writeTxn(() => col.putAll([obj1, obj2, obj3]));

        final Listener listenerLazy =
            Listener(col.filter().valueContains('H').watchLazy());
        final Listener listener =
            Listener(col.filter().valueContains('H').watch());

        isar.writeTxn(() => col.deleteAllByValue([obj1.value, obj2.value]));
        await listenerLazy.next;
        expect(await listener.next, <dynamic>[]);

        await isar.writeTxn(() => col.deleteAllByValue([obj3.value]));
        if (kIsWeb) {
          await listenerLazy.next;
          expect(await listener.next, <dynamic>[]);
        }

        await listenerLazy.done();
        await listener.done();
      });
    });
  });
}
