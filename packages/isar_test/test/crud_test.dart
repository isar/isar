import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'crud_test.g.dart';

@collection
class IntModel {
  const IntModel(this.id, this.value);

  final int id;

  final String value;

  @override
  // ignore: hash_and_equals
  bool operator ==(dynamic other) {
    if (other is IntModel) {
      return other.id == id && other.value == value;
    } else {
      return false;
    }
  }
}

@collection
class StringModel {
  const StringModel(this.id);

  final String id;

  @override
  // ignore: hash_and_equals
  bool operator ==(dynamic other) {
    if (other is StringModel) {
      return other.id == id;
    } else {
      return false;
    }
  }
}

void main() {
  group('CRUD', () {
    const intM1 = IntModel(1, 'This is a new model');
    const intM2 = IntModel(2, 'This is another new model');
    const intM3 = IntModel(3, 'Yet another one');
    const strM1 = StringModel('M1');
    const strM2 = StringModel('M2');
    const strM3 = StringModel('M3');
    late Isar isar;

    setUp(() async {
      isar = await openTempIsar([IntModelSchema, StringModelSchema]);
    });

    group('int id', () {
      isarTest('get()', () {
        expect(isar.intModels.get(intM1.id), null);
        expect(isar.intModels.get(intM2.id), null);

        isar.write((isar) {
          isar.intModels.put(intM1);
          expect(isar.intModels.get(intM1.id), intM1);
          expect(isar.intModels.get(intM2.id), null);

          isar.intModels.put(intM2);
          expect(isar.intModels.get(intM1.id), intM1);
          expect(isar.intModels.get(intM2.id), intM2);
        });

        expect(isar.intModels.get(intM1.id), intM1);
        expect(isar.intModels.get(intM2.id), intM2);
      });

      isarTest('put()', () {
        expect(
          isar.intModels.getAll([intM1.id, intM2.id, intM3.id]),
          [null, null, null],
        );

        isar.write((isar) {
          isar.intModels.put(intM1);
          expect(
            isar.intModels.getAll([intM1.id, intM2.id, intM3.id]),
            [intM1, null, null],
          );

          isar.intModels.put(intM3);
          expect(
            isar.intModels.getAll([intM1.id, intM2.id, intM3.id]),
            [intM1, null, intM3],
          );

          isar.intModels.put(intM2);
          expect(
            isar.intModels.getAll([intM1.id, intM2.id, intM3.id]),
            [intM1, intM2, intM3],
          );
        });

        expect(
          isar.intModels.getAll([intM1.id, intM2.id, intM3.id]),
          [intM1, intM2, intM3],
        );
      });

      isarTest('getAll()', () {
        expect(
          isar.intModels.getAll([intM1.id, intM2.id, intM3.id]),
          [null, null, null],
        );

        isar.write((isar) {
          isar.intModels.put(intM1);
          expect(
            isar.intModels.getAll([intM1.id, intM2.id, intM3.id]),
            [intM1, null, null],
          );

          isar.intModels.put(intM3);
          expect(
            isar.intModels.getAll([intM1.id, intM2.id, intM3.id]),
            [intM1, null, intM3],
          );
        });

        expect(
          isar.intModels.getAll([intM1.id, intM2.id, intM3.id]),
          [intM1, null, intM3],
        );
      });

      isarTest('putAll()', () {
        isar.write((isar) {
          isar.intModels.putAll([intM1, intM3, intM1]);
          expect(
            isar.intModels.getAll([intM1.id, intM2.id, intM3.id]),
            [intM1, null, intM3],
          );

          isar.intModels.putAll([intM2, intM2]);
          expect(
            isar.intModels.getAll([intM1.id, intM2.id, intM3.id]),
            [intM1, intM2, intM3],
          );

          isar.intModels.putAll([]);
          expect(
            isar.intModels.getAll([intM1.id, intM2.id, intM3.id]),
            [intM1, intM2, intM3],
          );
        });

        expect(
          isar.intModels.getAll([intM1.id, intM2.id, intM3.id]),
          [intM1, intM2, intM3],
        );
      });

      isarTest('delete()', () {
        isar.write((isar) {
          isar.intModels.putAll([intM1, intM2]);
          expect(isar.intModels.delete(intM2.id), true);
          expect(isar.intModels.getAll([intM1.id, intM2.id]), [intM1, null]);

          expect(isar.intModels.delete(intM2.id), false);
          expect(isar.intModels.getAll([intM1.id, intM2.id]), [intM1, null]);
        });

        expect(isar.intModels.getAll([intM1.id, intM2.id]), [intM1, null]);
      });

      isarTest('deleteAll()', () {
        isar.write((isar) {
          isar.intModels.putAll([intM1, intM2, intM3]);
          expect(isar.intModels.deleteAll([intM1.id, intM3.id]), 2);
          expect(
            isar.intModels.getAll([intM1.id, intM2.id, intM3.id]),
            [null, intM2, null],
          );

          expect(isar.intModels.deleteAll([intM1.id, intM2.id]), 1);
          expect(
            isar.intModels.getAll([intM1.id, intM2.id, intM3.id]),
            [null, null, null],
          );
        });

        expect(
          isar.intModels.getAll([intM1.id, intM2.id, intM3.id]),
          [null, null, null],
        );
      });
    });

    group('String id', () {
      isarTest('get()', () {
        expect(isar.stringModels.get(strM1.id), null);
        expect(isar.stringModels.get(strM2.id), null);

        isar.write((isar) {
          isar.stringModels.put(strM1);
          expect(isar.stringModels.get(strM1.id), strM1);
          expect(isar.stringModels.get(strM2.id), null);

          isar.stringModels.put(strM2);
          expect(isar.stringModels.get(strM1.id), strM1);
          expect(isar.stringModels.get(strM2.id), strM2);
        });

        expect(isar.stringModels.get(strM1.id), strM1);
        expect(isar.stringModels.get(strM2.id), strM2);
      });

      isarTest('put()', () {
        expect(isar.stringModels.getAll([strM1.id, strM2.id]), [null, null]);

        isar.write((isar) {
          isar.stringModels.put(strM1);
          expect(isar.stringModels.getAll([strM1.id, strM2.id]), [strM1, null]);

          isar.stringModels.put(strM2);
          expect(
            isar.stringModels.getAll([strM1.id, strM2.id]),
            [strM1, strM2],
          );
        });

        expect(isar.stringModels.getAll([strM1.id, strM2.id]), [strM1, strM2]);
      });

      isarTest('getAll()', () {
        expect(
          isar.stringModels.getAll([strM1.id, strM2.id, strM3.id]),
          [null, null, null],
        );

        isar.write((isar) {
          isar.stringModels.put(strM1);
          expect(
            isar.stringModels.getAll([strM1.id, strM2.id, strM3.id]),
            [strM1, null, null],
          );

          isar.stringModels.put(strM3);
          expect(
            isar.stringModels.getAll([strM1.id, strM2.id, strM3.id]),
            [strM1, null, strM3],
          );
        });

        expect(
          isar.stringModels.getAll([strM1.id, strM2.id, strM3.id]),
          [strM1, null, strM3],
        );
      });

      isarTest('putAll()', () {
        isar.write((isar) {
          isar.stringModels.putAll([strM1, strM3, strM1]);
          expect(
            isar.stringModels.getAll([strM1.id, strM2.id, strM3.id]),
            [strM1, null, strM3],
          );

          isar.stringModels.putAll([strM2, strM2]);
          expect(
            isar.stringModels.getAll([strM1.id, strM2.id, strM3.id]),
            [strM1, strM2, strM3],
          );

          isar.stringModels.putAll([]);
          expect(
            isar.stringModels.getAll([strM1.id, strM2.id, strM3.id]),
            [strM1, strM2, strM3],
          );
        });

        expect(
          isar.stringModels.getAll([strM1.id, strM2.id, strM3.id]),
          [strM1, strM2, strM3],
        );
      });

      isarTest('delete()', () {
        isar.write((isar) {
          isar.stringModels.putAll([strM1, strM2]);
          expect(isar.stringModels.delete(strM2.id), true);
          expect(isar.stringModels.getAll([strM1.id, strM2.id]), [strM1, null]);

          expect(isar.stringModels.delete(strM2.id), false);
          expect(isar.stringModels.getAll([strM1.id, strM2.id]), [strM1, null]);
        });

        expect(isar.stringModels.getAll([strM1.id, strM2.id]), [strM1, null]);
      });

      isarTest('deleteAll()', () {
        isar.write((isar) {
          isar.stringModels.putAll([strM1, strM2, strM3]);
          expect(isar.stringModels.deleteAll([strM1.id, strM3.id]), 2);
          expect(
            isar.stringModels.getAll([strM1.id, strM2.id, strM3.id]),
            [null, strM2, null],
          );

          expect(isar.stringModels.deleteAll([strM1.id, strM2.id]), 1);
          expect(
            isar.stringModels.getAll([strM1.id, strM2.id, strM3.id]),
            [null, null, null],
          );
        });

        expect(
          isar.stringModels.getAll([strM1.id, strM2.id, strM3.id]),
          [null, null, null],
        );
      });
    });

    isarTest('count()', () {
      expect(isar.intModels.count(), 0);
      expect(isar.stringModels.count(), 0);

      isar.write((isar) {
        isar.intModels.put(intM1);
        expect(isar.intModels.count(), 1);
        expect(isar.stringModels.count(), 0);

        isar.stringModels.put(strM1);
        expect(isar.intModels.count(), 1);
        expect(isar.stringModels.count(), 1);

        isar.intModels.put(intM2);
        expect(isar.intModels.count(), 2);
        expect(isar.stringModels.count(), 1);

        isar.stringModels.put(strM2);
        expect(isar.intModels.count(), 2);
        expect(isar.stringModels.count(), 2);
      });

      expect(isar.intModels.count(), 2);
      expect(isar.stringModels.count(), 2);
    });

    isarTest('clear()', () {
      isar.write((isar) {
        isar.intModels.putAll([intM1, intM2]);
        isar.stringModels.putAll([strM1, strM2]);
        expect(isar.intModels.count(), 2);
        expect(isar.stringModels.count(), 2);

        isar.intModels.clear();
        expect(isar.intModels.count(), 0);
        expect(isar.stringModels.count(), 2);

        isar.intModels.putAll([intM1, intM2]);
        isar.stringModels.clear();
        expect(isar.intModels.count(), 2);
        expect(isar.stringModels.count(), 0);
      });

      expect(isar.intModels.count(), 2);
      expect(isar.stringModels.count(), 0);
    });
  });
}
