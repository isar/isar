import 'package:isar/isar.dart';
import 'package:test/test.dart';

import 'common.dart';
import 'mutli_type_model.dart';

late Isar _isar;

IsarCollection<MultiTypeModel> get col => _isar.multiTypeModels;

void main() {
  group('Aggregation', () {
    setUp(() async {
      _isar = await openTempIsar([MultiTypeModelSchema]);
    });

    tearDown(() async {
      await _isar.close();
    });

    group('int', () {
      setUp(() async {
        await _isar.writeTxn((isar) => col.putAll([
              MultiTypeModel()..intValue = -5,
              MultiTypeModel()..intValue = 0,
              MultiTypeModel()
                ..intValue = 10
                ..intValueN = 10,
            ]));
      });

      isarTest('min', () async {
        expect(await col.where().intValueProperty().min(), -5);
        expect(await col.where().intValueNProperty().min(), 10);

        expect(
          await col
              .where()
              .filter()
              .intValueEqualTo(10)
              .intValueProperty()
              .min(),
          10,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .intValueProperty()
              .min(),
          null,
        );
      });

      isarTest('max', () async {
        expect(await col.where().intValueProperty().max(), 10);
        expect(await col.where().intValueNProperty().max(), 10);

        expect(
          await col
              .where()
              .filter()
              .intValueEqualTo(-5)
              .intValueProperty()
              .max(),
          -5,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .intValueProperty()
              .max(),
          null,
        );
      });

      isarTest('sum', () async {
        expect(await col.where().intValueProperty().sum(), 5);
        expect(await col.where().intValueNProperty().sum(), 10);

        expect(
          await col
              .where()
              .filter()
              .intValueEqualTo(10)
              .intValueProperty()
              .sum(),
          10,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .intValueProperty()
              .sum(),
          0,
        );
      });

      isarTest('average', () async {
        expect(await col.where().intValueProperty().average(), 5 / 3);
        expect(await col.where().intValueNProperty().average(), 10);

        expect(
          await col
              .where()
              .filter()
              .intValueEqualTo(10)
              .intValueProperty()
              .average(),
          10.0,
        );

        expect(
          (await col
                  .where()
                  .filter()
                  .boolValueEqualTo(true)
                  .intValueProperty()
                  .average())
              .isNaN,
          true,
        );
      });

      isarTest('count', () async {
        expect(await col.where().intValueProperty().count(), 3);
        expect(await col.where().intValueNProperty().count(), 3);

        expect(
          await col
              .where()
              .filter()
              .intValueEqualTo(10)
              .intValueProperty()
              .count(),
          1,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .intValueProperty()
              .count(),
          0,
        );
      });
    });

    group('float', () {
      setUp(() async {
        await _isar.writeTxn((isar) => col.putAll([
              MultiTypeModel()..floatValue = -5.0,
              MultiTypeModel()..floatValue = 0.0,
              MultiTypeModel()
                ..floatValue = 10.0
                ..floatValueN = 10.0,
            ]));
      });

      isarTest('min', () async {
        expect(await col.where().floatValueProperty().min(), -5.0);
        expect(await col.where().floatValueNProperty().min(), 10.0);

        expect(
          await col
              .where()
              .filter()
              .floatValueGreaterThan(9)
              .floatValueProperty()
              .min(),
          10.0,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .floatValueProperty()
              .min(),
          null,
        );
      });

      isarTest('max', () async {
        expect(await col.where().floatValueProperty().max(), 10.0);
        expect(await col.where().floatValueNProperty().max(), 10.0);

        expect(
          await col
              .where()
              .filter()
              .floatValueLessThan(-4.0)
              .floatValueProperty()
              .max(),
          -5.0,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .floatValueProperty()
              .max(),
          null,
        );
      });

      isarTest('sum', () async {
        expect(await col.where().floatValueProperty().sum(), 5.0);
        expect(await col.where().floatValueNProperty().sum(), 10.0);

        expect(
          await col
              .where()
              .filter()
              .floatValueGreaterThan(9)
              .floatValueProperty()
              .sum(),
          10.0,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .floatValueProperty()
              .sum(),
          0,
        );
      });

      isarTest('average', () async {
        expect(await col.where().floatValueProperty().average(), 5 / 3);
        expect(await col.where().floatValueNProperty().average(), 10.0);

        expect(
          await col
              .where()
              .filter()
              .floatValueGreaterThan(9)
              .floatValueProperty()
              .average(),
          10.0,
        );

        expect(
          (await col
                  .where()
                  .filter()
                  .boolValueEqualTo(true)
                  .floatValueProperty()
                  .average())
              .isNaN,
          true,
        );
      });

      isarTest('count', () async {
        expect(await col.where().floatValueProperty().count(), 3);
        expect(await col.where().floatValueNProperty().count(), 3);

        expect(
          await col
              .where()
              .filter()
              .floatValueGreaterThan(9)
              .floatValueProperty()
              .count(),
          1,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .floatValueProperty()
              .count(),
          0,
        );
      });
    });

    group('long', () {
      setUp(() async {
        await _isar.writeTxn((isar) => col.putAll([
              MultiTypeModel()..longValue = -5,
              MultiTypeModel()..longValue = 0,
              MultiTypeModel()
                ..longValue = 10
                ..longValueN = 10,
            ]));
      });

      isarTest('min', () async {
        expect(await col.where().longValueProperty().min(), -5);
        expect(await col.where().longValueNProperty().min(), 10);

        expect(
          await col
              .where()
              .filter()
              .longValueEqualTo(10)
              .longValueProperty()
              .min(),
          10,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .longValueProperty()
              .min(),
          null,
        );
      });

      isarTest('max', () async {
        expect(await col.where().longValueProperty().max(), 10);
        expect(await col.where().longValueNProperty().max(), 10);

        expect(
          await col
              .where()
              .filter()
              .longValueEqualTo(-5)
              .longValueProperty()
              .max(),
          -5,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .longValueProperty()
              .max(),
          null,
        );
      });

      isarTest('sum', () async {
        expect(await col.where().longValueProperty().sum(), 5);
        expect(await col.where().longValueNProperty().sum(), 10);

        expect(
          await col
              .where()
              .filter()
              .longValueEqualTo(10)
              .longValueProperty()
              .sum(),
          10,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .longValueProperty()
              .sum(),
          0,
        );
      });

      isarTest('average', () async {
        expect(await col.where().longValueProperty().average(), 5 / 3);
        expect(await col.where().longValueNProperty().average(), 10);

        expect(
          await col
              .where()
              .filter()
              .longValueEqualTo(10)
              .longValueProperty()
              .average(),
          10.0,
        );

        expect(
          (await col
                  .where()
                  .filter()
                  .boolValueEqualTo(true)
                  .longValueProperty()
                  .average())
              .isNaN,
          true,
        );
      });

      isarTest('count', () async {
        expect(await col.where().longValueProperty().count(), 3);
        expect(await col.where().longValueNProperty().count(), 3);

        expect(
          await col
              .where()
              .filter()
              .longValueEqualTo(10)
              .longValueProperty()
              .count(),
          1,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .longValueProperty()
              .count(),
          0,
        );
      });
    });

    group('double', () {
      setUp(() async {
        await _isar.writeTxn((isar) => col.putAll([
              MultiTypeModel()..doubleValue = -5.0,
              MultiTypeModel()..doubleValue = 0.0,
              MultiTypeModel()
                ..doubleValue = 10.0
                ..doubleValueN = 10.0,
            ]));
      });

      isarTest('min', () async {
        expect(await col.where().doubleValueProperty().min(), -5.0);
        expect(await col.where().doubleValueNProperty().min(), 10.0);

        expect(
          await col
              .where()
              .filter()
              .doubleValueGreaterThan(9)
              .doubleValueProperty()
              .min(),
          10.0,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .doubleValueProperty()
              .min(),
          null,
        );
      });

      isarTest('max', () async {
        expect(await col.where().doubleValueProperty().max(), 10.0);
        expect(await col.where().doubleValueNProperty().max(), 10.0);

        expect(
          await col
              .where()
              .filter()
              .doubleValueLessThan(-4.0)
              .doubleValueProperty()
              .max(),
          -5.0,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .doubleValueProperty()
              .max(),
          null,
        );
      });

      isarTest('sum', () async {
        expect(await col.where().doubleValueProperty().sum(), 5.0);
        expect(await col.where().doubleValueNProperty().sum(), 10.0);

        expect(
          await col
              .where()
              .filter()
              .doubleValueGreaterThan(9)
              .doubleValueProperty()
              .sum(),
          10.0,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .doubleValueProperty()
              .sum(),
          0,
        );
      });

      isarTest('average', () async {
        expect(await col.where().doubleValueProperty().average(), 5 / 3);
        expect(await col.where().doubleValueNProperty().average(), 10.0);

        expect(
          await col
              .where()
              .filter()
              .doubleValueGreaterThan(9)
              .doubleValueProperty()
              .average(),
          10.0,
        );

        expect(
          (await col
                  .where()
                  .filter()
                  .boolValueEqualTo(true)
                  .doubleValueProperty()
                  .average())
              .isNaN,
          true,
        );
      });

      isarTest('count', () async {
        expect(await col.where().doubleValueProperty().count(), 3);
        expect(await col.where().doubleValueNProperty().count(), 3);

        expect(
          await col
              .where()
              .filter()
              .doubleValueGreaterThan(9)
              .doubleValueProperty()
              .count(),
          1,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .doubleValueProperty()
              .count(),
          0,
        );
      });
    });

    group('DateTime', () {
      DateTime date(int milliseconds) =>
          DateTime.fromMillisecondsSinceEpoch(milliseconds);

      setUp(() async {
        await _isar.writeTxn((isar) => col.putAll([
              MultiTypeModel()..dateTimeValue = date(-5),
              MultiTypeModel()..dateTimeValue = date(0),
              MultiTypeModel()
                ..dateTimeValue = date(10)
                ..dateTimeValueN = date(10),
            ]));
      });

      isarTest('min', () async {
        expect(await col.where().dateTimeValueProperty().min(), date(-5));
        expect(await col.where().dateTimeValueNProperty().min(), date(10));

        expect(
          await col
              .where()
              .filter()
              .dateTimeValueEqualTo(date(10))
              .dateTimeValueProperty()
              .min(),
          date(10),
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .dateTimeValueProperty()
              .min(),
          null,
        );
      });

      isarTest('max', () async {
        expect(await col.where().dateTimeValueProperty().max(), date(10));
        expect(await col.where().dateTimeValueNProperty().max(), date(10));

        expect(
          await col
              .where()
              .filter()
              .dateTimeValueEqualTo(date(-5))
              .dateTimeValueProperty()
              .max(),
          date(-5),
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .dateTimeValueProperty()
              .max(),
          null,
        );
      });

      isarTest('count', () async {
        expect(await col.where().dateTimeValueProperty().count(), 3);
        expect(await col.where().dateTimeValueNProperty().count(), 3);

        expect(
          await col
              .where()
              .filter()
              .dateTimeValueEqualTo(date(10))
              .dateTimeValueProperty()
              .count(),
          1,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .dateTimeValueProperty()
              .count(),
          0,
        );
      });
    });
  });
}
