import 'dart:async';

import 'package:isar/isar.dart';
import 'package:isar_test/common.dart';
import 'package:test/test.dart';

part 'watcher_test.g.dart';

@Collection()
class Value {
  int? id;

  @Index(unique: true)
  String? value;

  Value(this.id, this.value);

  @override
  operator ==(other) =>
      other is Value && id == other.id && value == other.value;
}

class Listener<T> {
  late StreamSubscription subscription;
  final _unprocessed = <T>[];
  Completer<T>? _completer;

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

  Future<T> get next {
    if (_unprocessed.isEmpty) {
      expect(_completer, null);
      _completer = Completer<T>();
      return _completer!.future;
    } else {
      return Future.value(_unprocessed.removeAt(0));
    }
  }

  Future done() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await subscription.cancel();
    expect(_completer, null);
    expect(_unprocessed, []);
  }
}

void main() {
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
        final listener = Listener(col.watchLazy());

        isar.writeTxn((isar) => col.put(obj1));
        await listener.next;

        isar.writeTxn((isar) => col.put(obj1));
        await listener.next;

        await listener.done();
      });

      isarTest('.putAll()', () async {
        final listener = Listener(col.watchLazy());

        isar.writeTxn((isar) => col.putAll([obj1, obj2]));
        await listener.next;

        isar.writeTxn((isar) => col.putAll([obj1]));
        await listener.next;

        await listener.done();
      });

      isarTest('.delete()', () async {
        await isar.writeTxn((isar) => col.putAll([obj1, obj2]));

        final listener = Listener(col.watchLazy());

        isar.writeTxn((isar) => col.delete(1));
        await listener.next;

        isar.writeTxn((isar) => col.delete(2));
        await listener.next;

        await listener.done();
      });

      isarTest('.deleteAll()', () async {
        await isar.writeTxn((isar) => col.putAll([obj1, obj2]));

        final listener = Listener(col.watchLazy());

        isar.writeTxn((isar) => col.deleteAll([1, 3]));
        await listener.next;

        isar.writeTxn((isar) => col.deleteAll([2]));
        await listener.next;

        await listener.done();
      });

      isarTest('.deleteBy()', () async {
        await isar.writeTxn((isar) => col.putAll([obj1, obj2]));

        final listener = Listener(col.watchLazy());

        isar.writeTxn((isar) => col.deleteByValue(obj1.value));
        await listener.next;

        isar.writeTxn((isar) => col.deleteByValue(obj2.value));
        await listener.next;

        await listener.done();
      });

      isarTest('.deleteAllBy()', () async {
        await isar.writeTxn((isar) => col.putAll([obj1, obj2]));

        final listener = Listener(col.watchLazy());

        isar.writeTxn(
            (isar) => col.deleteAllByValue([obj1.value, 'something']));
        await listener.next;

        isar.writeTxn((isar) => col.deleteAllByValue([obj2.value]));
        await listener.next;

        await listener.done();
      });
    });

    group('Object', () {
      isarTest('.put()', () async {
        final listenerLazy = Listener(col.watchObjectLazy(1));
        final listener = Listener(col.watchObject(2));

        isar.writeTxn((isar) => col.put(obj1));
        await listenerLazy.next;

        isar.writeTxn((isar) => col.put(obj2));
        expect(await listener.next, obj2);

        await listenerLazy.done();
        await listener.done();
      });

      isarTest('.putAll()', () async {
        final listenerLazy = Listener(col.watchObjectLazy(1));
        final listener = Listener(col.watchObject(2));

        isar.writeTxn((isar) => col.putAll([obj1, obj3]));
        await listenerLazy.next;

        isar.writeTxn((isar) => col.putAll([obj1, obj2]));
        await listenerLazy.next;
        expect(await listener.next, obj2);

        await listenerLazy.done();
        await listener.done();
      });

      isarTest('.delete()', () async {
        await isar.writeTxn((isar) => col.putAll([obj1, obj2, obj3]));

        final listenerLazy = Listener(col.watchObjectLazy(1));
        final listener = Listener(col.watchObject(2));

        isar.writeTxn((isar) => col.delete(1));
        await listenerLazy.next;

        isar.writeTxn((isar) => col.delete(2));
        expect(await listener.next, null);

        await listenerLazy.done();
        await listener.done();
      });

      isarTest('.deleteAll()', () async {
        await isar.writeTxn((isar) => col.putAll([obj1, obj2, obj3]));

        final listenerLazy = Listener(col.watchObjectLazy(1));
        final listener = Listener(col.watchObject(2));

        isar.writeTxn((isar) => col.deleteAll([4, 1]));
        await listenerLazy.next;

        isar.writeTxn((isar) => col.deleteAll([2, 3]));
        expect(await listener.next, null);

        await listenerLazy.done();
        await listener.done();
      });

      isarTest('.deleteBy()', () async {
        await isar.writeTxn((isar) => col.putAll([obj1, obj2, obj3]));

        final listenerLazy = Listener(col.watchObjectLazy(1));
        final listener = Listener(col.watchObject(2));

        isar.writeTxn((isar) => col.deleteByValue(obj1.value));
        await listenerLazy.next;

        isar.writeTxn((isar) => col.deleteByValue(obj2.value));
        expect(await listener.next, null);

        await listenerLazy.done();
        await listener.done();
      });

      isarTest('.deleteAllBy()', () async {
        await isar.writeTxn((isar) => col.putAll([obj1, obj2, obj3]));

        final listenerLazy = Listener(col.watchObjectLazy(1));
        final listener = Listener(col.watchObject(2));

        isar.writeTxn((isar) => col.deleteAllByValue(['AAA', obj1.value]));
        await listenerLazy.next;

        isar.writeTxn((isar) => col.deleteAllByValue([obj2.value, obj3.value]));
        expect(await listener.next, null);

        await listenerLazy.done();
        await listener.done();
      });
    });

    group('Query', () {
      isarTest('.put()', () async {
        final listenerLazy =
            Listener(col.where().valueEqualTo('Hello').watchLazy());
        final listener = Listener(col.where().valueEqualTo('Hi').watch());

        isar.writeTxn((isar) => col.put(obj1));
        await listenerLazy.next;

        isar.writeTxn((isar) => col.put(obj2));
        expect(await listener.next, [obj2]);

        await listenerLazy.done();
        await listener.done();
      });

      isarTest('.putAll()', () async {
        final listenerLazy =
            Listener(col.filter().valueContains('H').watchLazy());
        final listener = Listener(col.filter().valueContains('H').watch());

        isar.writeTxn((isar) => col.putAll([obj1, obj2]));
        await listenerLazy.next;
        expect(await listener.next, [obj1, obj2]);

        await isar.writeTxn((isar) => col.putAll([obj3]));

        await listenerLazy.done();
        await listener.done();
      });

      isarTest('.delete()', () async {
        await isar.writeTxn((isar) => col.putAll([obj1, obj2, obj3]));

        final listenerLazy =
            Listener(col.where().valueEqualTo('Hello').watchLazy());
        final listener = Listener(col.where().valueEqualTo('Hi').watch());

        isar.writeTxn((isar) => col.delete(1));
        await listenerLazy.next;
        if (kIsWeb) {
          expect(await listener.next, [obj2]);
        }

        isar.writeTxn((isar) => col.delete(2));
        if (kIsWeb) {
          await listenerLazy.next;
        }
        expect(await listener.next, []);

        await listenerLazy.done();
        await listener.done();
      });

      isarTest('.deleteAll()', () async {
        await isar.writeTxn((isar) => col.putAll([obj1, obj2, obj3]));

        final listenerLazy =
            Listener(col.filter().valueContains('H').watchLazy());
        final listener = Listener(col.filter().valueContains('H').watch());

        isar.writeTxn((isar) => col.deleteAll([1, 2]));
        await listenerLazy.next;
        expect(await listener.next, []);

        await isar.writeTxn((isar) => col.deleteAll([3]));
        if (kIsWeb) {
          await listenerLazy.next;
          expect(await listener.next, []);
        }

        await listenerLazy.done();
        await listener.done();
      });

      isarTest('.deleteBy()', () async {
        await isar.writeTxn((isar) => col.putAll([obj1, obj2, obj3]));

        final listenerLazy =
            Listener(col.where().valueEqualTo('Hello').watchLazy());
        final listener = Listener(col.where().valueEqualTo('Hi').watch());

        isar.writeTxn((isar) => col.deleteByValue(obj1.value));
        await listenerLazy.next;
        if (kIsWeb) {
          expect(await listener.next, [obj2]);
        }

        isar.writeTxn((isar) => col.deleteByValue(obj2.value));
        if (kIsWeb) {
          await listenerLazy.next;
        }
        expect(await listener.next, []);

        await listenerLazy.done();
        await listener.done();
      });

      isarTest('.deleteAllByValue()', () async {
        await isar.writeTxn((isar) => col.putAll([obj1, obj2, obj3]));

        final listenerLazy =
            Listener(col.filter().valueContains('H').watchLazy());
        final listener = Listener(col.filter().valueContains('H').watch());

        isar.writeTxn((isar) => col.deleteAllByValue([obj1.value, obj2.value]));
        await listenerLazy.next;
        expect(await listener.next, []);

        await isar.writeTxn((isar) => col.deleteAllByValue([obj3.value]));
        if (kIsWeb) {
          await listenerLazy.next;
          expect(await listener.next, []);
        }

        await listenerLazy.done();
        await listener.done();
      });
    });
  });
}
