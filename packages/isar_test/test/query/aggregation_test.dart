import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

import '../type_models.dart';

void main() {
  group('Aggregation', () {
    group('id', () {
      late IsarCollection<int, IntModel> col;

      setUp(() async {
        final isar = await openTempIsar([IntModelSchema]);
        col = isar.intModels;

        isar.write(
          (isar) => col.putAll([
            IntModel(-5),
            IntModel(0),
            IntModel(10),
          ]),
        );
      });

      isarTest('min', () {
        expect(col.where().idProperty().min(), -5);
        expect(col.where().idEqualTo(10).idProperty().min(), 10);
        expect(col.where().idEqualTo(99).idProperty().min(), null);
      });

      isarTest('max', () {
        expect(col.where().idProperty().max(), 10);
        expect(col.where().idEqualTo(10).idProperty().max(), 10);
        expect(col.where().idEqualTo(99).idProperty().max(), null);
      });

      isarTest('sum', () {
        expect(col.where().idProperty().sum(), 5);
        expect(col.where().idEqualTo(10).idProperty().sum(), 10);
        expect(col.where().idEqualTo(99).idProperty().sum(), 0);
      });

      isarTest('average', () {
        expect(col.where().idProperty().average(), 5.0 / 3);
        expect(col.where().idEqualTo(10).idProperty().average(), 10);
        expect(col.where().idEqualTo(99).idProperty().average(), isNaN);
      });
    });

    group('byte', () {
      late IsarCollection<int, ByteModel> col;

      setUp(() async {
        final isar = await openTempIsar([ByteModelSchema]);
        col = isar.byteModels;

        isar.write(
          (isar) => col.putAll([
            ByteModel(0)..value = 1,
            ByteModel(1)..value = 5,
            ByteModel(2)..value = 2,
          ]),
        );
      });

      isarTest('min', () {
        expect(col.where().valueProperty().min(), 1);
        expect(col.where().valueEqualTo(5).valueProperty().min(), 5);
        expect(col.where().valueEqualTo(25).valueProperty().min(), null);
      });

      isarTest('max', () {
        expect(col.where().valueProperty().max(), 5);
        expect(col.where().valueEqualTo(2).valueProperty().max(), 2);
        expect(col.where().valueEqualTo(25).valueProperty().max(), null);
      });

      isarTest('sum', () {
        expect(col.where().valueProperty().sum(), 8);
        expect(col.where().valueEqualTo(2).valueProperty().sum(), 2);
        expect(col.where().valueEqualTo(25).valueProperty().sum(), 0);
      });

      isarTest('average', () {
        expect(col.where().valueProperty().average(), 8.0 / 3);
        expect(col.where().valueEqualTo(2).valueProperty().average(), 2);
        expect(
          col.where().valueEqualTo(25).valueProperty().average(),
          isNaN,
        );
      });
    });

    group('short', () {
      late IsarCollection<int, ShortModel> col;

      setUp(() async {
        final isar = await openTempIsar([ShortModelSchema]);
        col = isar.shortModels;

        isar.write(
          (isar) => col.putAll([
            ShortModel(0)
              ..value = 3
              ..nValue = -5,
            ShortModel(1)..nValue = 0,
            ShortModel(2)
              ..value = -2
              ..nValue = 10,
            ShortModel(3)..nValue = null,
          ]),
        );
      });

      isarTest('min', () {
        expect(col.where().nValueProperty().min(), -5);
        expect(col.where().valueProperty().min(), -2);
        expect(col.where().nValueEqualTo(10).nValueProperty().min(), 10);
        expect(col.where().nValueEqualTo(null).nValueProperty().min(), null);
      });

      isarTest('max', () {
        expect(col.where().nValueProperty().max(), 10);
        expect(col.where().valueProperty().max(), 3);
        expect(col.where().nValueEqualTo(10).nValueProperty().max(), 10);
        expect(col.where().nValueEqualTo(null).nValueProperty().max(), null);
      });

      isarTest('sum', () {
        expect(col.where().nValueProperty().sum(), 5);
        expect(col.where().valueProperty().sum(), 1);
        expect(col.where().nValueEqualTo(10).nValueProperty().sum(), 10);
        expect(col.where().nValueEqualTo(null).nValueProperty().sum(), 0);
      });

      isarTest('average', () {
        expect(col.where().nValueProperty().average(), 5.0 / 3);
        expect(col.where().valueProperty().average(), 1 / 4);
        expect(col.where().nValueEqualTo(10).nValueProperty().average(), 10);
        expect(
          col.where().nValueEqualTo(null).nValueProperty().average(),
          isNaN,
        );
      });
    });

    group('int', () {
      late IsarCollection<int, IntModel> col;

      setUp(() async {
        final isar = await openTempIsar([IntModelSchema]);
        col = isar.intModels;

        isar.write(
          (isar) => col.putAll([
            IntModel(0)
              ..value = 3
              ..nValue = -5,
            IntModel(1)..nValue = 0,
            IntModel(2)
              ..value = -2
              ..nValue = 10,
            IntModel(3)..nValue = null,
          ]),
        );
      });

      isarTest('min', () {
        expect(col.where().nValueProperty().min(), -5);
        expect(col.where().valueProperty().min(), -2);
        expect(col.where().nValueEqualTo(10).nValueProperty().min(), 10);
        expect(col.where().nValueEqualTo(null).nValueProperty().min(), null);
      });

      isarTest('max', () {
        expect(col.where().nValueProperty().max(), 10);
        expect(col.where().valueProperty().max(), 3);
        expect(col.where().nValueEqualTo(10).nValueProperty().max(), 10);
        expect(col.where().nValueEqualTo(null).nValueProperty().max(), null);
      });

      isarTest('sum', () {
        expect(col.where().nValueProperty().sum(), 5);
        expect(col.where().valueProperty().sum(), 1);
        expect(col.where().nValueEqualTo(10).nValueProperty().sum(), 10);
        expect(col.where().nValueEqualTo(null).nValueProperty().sum(), 0);
      });

      isarTest('average', () {
        expect(col.where().nValueProperty().average(), 5.0 / 3);
        expect(col.where().valueProperty().average(), 1 / 4);
        expect(col.where().nValueEqualTo(10).nValueProperty().average(), 10);
        expect(
          col.where().nValueEqualTo(null).nValueProperty().average(),
          isNaN,
        );
      });
    });

    group('float', () {
      late IsarCollection<int, FloatModel> col;

      setUp(() async {
        final isar = await openTempIsar([FloatModelSchema]);
        col = isar.floatModels;

        isar.write(
          (isar) => col.putAll([
            FloatModel(0)
              ..value = 3
              ..nValue = -5,
            FloatModel(1)..nValue = 0,
            FloatModel(2)
              ..value = -2
              ..nValue = 10,
            FloatModel(3)..nValue = null,
          ]),
        );
      });

      isarTest('min', () {
        expect(col.where().nValueProperty().min(), -5);
        expect(col.where().valueProperty().min(), -2);
        expect(col.where().nValueEqualTo(10).nValueProperty().min(), 10);
        expect(col.where().nValueEqualTo(null).nValueProperty().min(), null);
      });

      isarTest('max', () {
        expect(col.where().nValueProperty().max(), 10);
        expect(col.where().valueProperty().max(), 3);
        expect(col.where().nValueEqualTo(10).nValueProperty().max(), 10);
        expect(col.where().nValueEqualTo(null).nValueProperty().max(), null);
      });

      isarTest('sum', () {
        expect(col.where().nValueProperty().sum(), 5);
        expect(col.where().valueProperty().sum(), 1);
        expect(col.where().nValueEqualTo(10).nValueProperty().sum(), 10);
        expect(col.where().nValueEqualTo(null).nValueProperty().sum(), 0);
      });

      isarTest('average', () {
        expect(col.where().nValueProperty().average(), 5.0 / 3);
        expect(col.where().valueProperty().average(), 1 / 4);
        expect(col.where().nValueEqualTo(10).nValueProperty().average(), 10);
        expect(
          col.where().nValueEqualTo(null).nValueProperty().average(),
          isNaN,
        );
      });
    });

    group('double', () {
      late IsarCollection<int, DoubleModel> col;

      setUp(() async {
        final isar = await openTempIsar([DoubleModelSchema]);
        col = isar.doubleModels;

        isar.write(
          (isar) => col.putAll([
            DoubleModel(0)
              ..value = 3
              ..nValue = -5,
            DoubleModel(1)..nValue = 0,
            DoubleModel(2)
              ..value = -2
              ..nValue = 10,
            DoubleModel(3)..nValue = null,
          ]),
        );
      });

      isarTest('min', () {
        expect(col.where().nValueProperty().min(), -5);
        expect(col.where().valueProperty().min(), -2);
        expect(col.where().nValueEqualTo(10).nValueProperty().min(), 10);
        expect(col.where().nValueEqualTo(null).nValueProperty().min(), null);
      });

      isarTest('max', () {
        expect(col.where().nValueProperty().max(), 10);
        expect(col.where().valueProperty().max(), 3);
        expect(col.where().nValueEqualTo(10).nValueProperty().max(), 10);
        expect(col.where().nValueEqualTo(null).nValueProperty().max(), null);
      });

      isarTest('sum', () {
        expect(col.where().nValueProperty().sum(), 5);
        expect(col.where().valueProperty().sum(), 1);
        expect(col.where().nValueEqualTo(10).nValueProperty().sum(), 10);
        expect(col.where().nValueEqualTo(null).nValueProperty().sum(), 0);
      });

      isarTest('average', () {
        expect(col.where().nValueProperty().average(), 5.0 / 3);
        expect(col.where().valueProperty().average(), 1 / 4);
        expect(col.where().nValueEqualTo(10).nValueProperty().average(), 10);
        expect(
          col.where().nValueEqualTo(null).nValueProperty().average(),
          isNaN,
        );
      });
    });
  });
}
