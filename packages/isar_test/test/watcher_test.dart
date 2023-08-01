import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'watcher_test.g.dart';

@collection
class Value {
  Value(this.id, this.value);

  int id;

  @Index(unique: true)
  String? value;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is Value && id == other.id && value == other.value;
}

void main() {
  group('Watcher', () {
    late Isar isar;

    late Value obj1;
    late Value obj2;
    late Value obj3;

    setUp(() async {
      isar = await openTempIsar([ValueSchema]);

      obj1 = Value(1, 'Hello');
      obj2 = Value(2, 'Hi');
      obj3 = Value(3, 'Test');
    });

    group('Collection', () {
      isarTest('.put()', web: false, () async {
        final listener = Listener<void>(isar.values.watchLazy());

        isar.write((isar) => isar.values.put(obj1));
        await listener.next;

        isar.write((isar) => isar.values.put(obj1));
        await listener.next;

        await listener.done();
      });

      isarTest('.putAll()', web: false, () async {
        final listener = Listener<void>(isar.values.watchLazy());

        isar.write((isar) => isar.values.putAll([obj1, obj2]));
        await listener.next;

        isar.write((isar) => isar.values.putAll([obj1]));
        await listener.next;

        await listener.done();
      });

      isarTest('.delete()', web: false, () async {
        isar.write((isar) => isar.values.putAll([obj1, obj2]));

        final listener = Listener<void>(isar.values.watchLazy());

        isar.write((isar) => isar.values.delete(1));
        await listener.next;

        isar.write((isar) => isar.values.delete(2));
        await listener.next;

        await listener.done();
      });

      isarTest('.deleteAll()', web: false, () async {
        isar.write((isar) => isar.values.putAll([obj1, obj2]));

        final listener = Listener<void>(isar.values.watchLazy());

        isar.write((isar) => isar.values.deleteAll([1, 3]));
        await listener.next;

        isar.write((isar) => isar.values.deleteAll([2]));
        await listener.next;

        await listener.done();
      });

      isarTest('fireImmediately', web: false, () async {
        final listener = Listener<void>(
          isar.values.watchLazy(fireImmediately: true),
        );

        await listener.next;
        isar.write((isar) => isar.values.put(obj1));
        await listener.next;

        await listener.done();
      });
    });

    group('Object', () {
      isarTest('.put()', web: false, () async {
        final listenerLazy = Listener<void>(isar.values.watchObjectLazy(1));
        final listener = Listener<Value?>(isar.values.watchObject(2));

        isar.write((isar) => isar.values.put(obj1));
        await listenerLazy.next;

        isar.write((isar) => isar.values.put(obj2));
        expect(await listener.next, obj2);

        await listenerLazy.done();
        await listener.done();
      });

      isarTest('.putAll()', web: false, () async {
        final listenerLazy = Listener<void>(isar.values.watchObjectLazy(1));
        final listener = Listener<Value?>(isar.values.watchObject(2));

        isar.write((isar) => isar.values.putAll([obj1, obj3]));
        await listenerLazy.next;

        isar.write((isar) => isar.values.putAll([obj1, obj2]));
        await listenerLazy.next;
        expect(await listener.next, obj2);

        await listenerLazy.done();
        await listener.done();
      });

      isarTest('.delete()', web: false, () async {
        isar.write((isar) => isar.values.putAll([obj1, obj2, obj3]));

        final listenerLazy = Listener<void>(isar.values.watchObjectLazy(1));
        final listener = Listener<Value?>(isar.values.watchObject(2));

        isar.write((isar) => isar.values.delete(1));
        await listenerLazy.next;

        isar.write((isar) => isar.values.delete(2));
        expect(await listener.next, null);

        await listenerLazy.done();
        await listener.done();
      });

      isarTest('.deleteAll()', web: false, () async {
        isar.write((isar) => isar.values.putAll([obj1, obj2, obj3]));

        final listenerLazy = Listener<void>(isar.values.watchObjectLazy(1));
        final listener = Listener<Value?>(isar.values.watchObject(2));

        isar.write((isar) => isar.values.deleteAll([4, 1]));
        await listenerLazy.next;

        isar.write((isar) => isar.values.deleteAll([2, 3]));
        expect(await listener.next, null);

        await listenerLazy.done();
        await listener.done();
      });

      isarTest('fireImmediately', web: false, () async {
        final listenerLazy = Listener<void>(
          isar.values.watchObjectLazy(1, fireImmediately: true),
        );
        final listener = Listener<Value?>(
          isar.values.watchObject(1, fireImmediately: true),
        );

        await listenerLazy.next;
        expect(await listener.next, null);
        isar.write((isar) => isar.values.put(obj1));
        await listenerLazy.next;
        expect(await listener.next, obj1);

        await listenerLazy.done();
        await listener.done();
      });
    });

    group('Query', () {
      isarTest('.put()', web: false, () async {
        final listenerLazy =
            Listener(isar.values.where().valueEqualTo('Hello').watchLazy());
        final listener =
            Listener(isar.values.where().valueEqualTo('Hi').watch());

        isar.write((isar) => isar.values.put(obj1));
        await listenerLazy.next;
        if (isSQLite) {
          expect(await listener.next, isEmpty);
        }

        isar.write((isar) => isar.values.put(obj2));
        expect(await listener.next, [obj2]);
        if (isSQLite) {
          await listenerLazy.next;
        }

        await listenerLazy.done();
        await listener.done();
      });

      isarTest('.putAll()', web: false, () async {
        final listenerLazy =
            Listener(isar.values.where().valueContains('H').watchLazy());
        final listener =
            Listener(isar.values.where().valueContains('H').watch());

        isar.write((isar) => isar.values.putAll([obj1, obj2]));
        await listenerLazy.next;
        expect(await listener.next, [obj1, obj2]);

        isar.write((isar) => isar.values.putAll([obj3]));
        if (isSQLite) {
          await listenerLazy.next;
          expect(await listener.next, [obj1, obj2]);
        }

        await listenerLazy.done();
        await listener.done();
      });

      isarTest('.delete()', web: false, () async {
        isar.write((isar) => isar.values.putAll([obj1, obj2, obj3]));

        final listenerLazy =
            Listener(isar.values.where().valueEqualTo('Hello').watchLazy());
        final listener =
            Listener(isar.values.where().valueEqualTo('Hi').watch());

        isar.write((isar) => isar.values.delete(1));
        await listenerLazy.next;
        if (isSQLite) {
          expect(await listener.next, [obj2]);
        }

        isar.write((isar) => isar.values.delete(2));
        if (isSQLite) {
          await listenerLazy.next;
        }
        expect(await listener.next, <dynamic>[]);

        await listenerLazy.done();
        await listener.done();
      });

      isarTest('.deleteAll()', web: false, () async {
        isar.write((isar) => isar.values.putAll([obj1, obj2, obj3]));

        final listenerLazy =
            Listener(isar.values.where().valueContains('H').watchLazy());
        final listener =
            Listener(isar.values.where().valueContains('H').watch());

        isar.write((isar) => isar.values.deleteAll([1, 2]));
        await listenerLazy.next;
        expect(await listener.next, <dynamic>[]);

        isar.write((isar) => isar.values.deleteAll([3]));
        if (isSQLite) {
          await listenerLazy.next;
          expect(await listener.next, <dynamic>[]);
        }

        await listenerLazy.done();
        await listener.done();
      });

      isarTest('fireImmediately', web: false, () async {
        final listenerLazy = Listener(
          isar.values
              .where()
              .valueEqualTo('Hello')
              .watchLazy(fireImmediately: true),
        );
        final listener = Listener(
          isar.values
              .where()
              .valueEqualTo('Hello')
              .watch(fireImmediately: true),
        );

        await listenerLazy.next;
        expect(await listener.next, isEmpty);
        isar.write((isar) => isar.values.put(obj1));
        await listenerLazy.next;
        expect(await listener.next, [obj1]);

        await listenerLazy.done();
        await listener.done();
      });
    });
  });
}
