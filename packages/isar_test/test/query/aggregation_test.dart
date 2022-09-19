import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

import '../mutli_type_model.dart';

void main() {
  group('Aggregation', () {
    late Isar isar;
    late IsarCollection<MultiTypeModel> col;

    setUp(() async {
      isar = await openTempIsar([MultiTypeModelSchema]);
      col = isar.multiTypeModels;
    });

    group('int', () {
      setUp(() async {
        await isar.writeTxn(
          () => col.putAll([
            MultiTypeModel()..intValue = -5,
            MultiTypeModel()..intValue = 0,
            MultiTypeModel()
              ..intValue = 10
              ..intValueN = 10,
          ]),
        );
      });

      isarTest('min', () async {
        expect(await col.where().intValueProperty().tMin(), -5);
        expect(await col.where().intValueNProperty().tMin(), 10);

        expect(
          await col
              .where()
              .filter()
              .intValueEqualTo(10)
              .intValueProperty()
              .tMin(),
          10,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .intValueProperty()
              .tMin(),
          null,
        );
      });

      isarTest('max', () async {
        expect(await col.where().intValueProperty().tMax(), 10);
        expect(await col.where().intValueNProperty().tMax(), 10);

        expect(
          await col
              .where()
              .filter()
              .intValueEqualTo(-5)
              .intValueProperty()
              .tMax(),
          -5,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .intValueProperty()
              .tMax(),
          null,
        );
      });

      isarTest('sum', () async {
        expect(await col.where().intValueProperty().tSum(), 5);
        expect(await col.where().intValueNProperty().tSum(), 10);

        expect(
          await col
              .where()
              .filter()
              .intValueEqualTo(10)
              .intValueProperty()
              .tSum(),
          10,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .intValueProperty()
              .tSum(),
          0,
        );
      });

      isarTest('average', () async {
        expect(await col.where().intValueProperty().tAverage(), 5 / 3);
        expect(await col.where().intValueNProperty().tAverage(), 10);

        expect(
          await col
              .where()
              .filter()
              .intValueEqualTo(10)
              .intValueProperty()
              .tAverage(),
          10.0,
        );

        expect(
          (await col
                  .where()
                  .filter()
                  .boolValueEqualTo(true)
                  .intValueProperty()
                  .tAverage())
              .isNaN,
          true,
        );
      });

      isarTest('count', () async {
        expect(await col.where().intValueProperty().tCount(), 3);
        expect(await col.where().intValueNProperty().tCount(), 3);

        expect(
          await col
              .where()
              .filter()
              .intValueEqualTo(10)
              .intValueProperty()
              .tCount(),
          1,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .intValueProperty()
              .tCount(),
          0,
        );
      });
    });

    group('float', () {
      setUp(() async {
        await isar.writeTxn(
          () => col.putAll([
            MultiTypeModel()..floatValue = -5.0,
            MultiTypeModel()..floatValue = 0.0,
            MultiTypeModel()
              ..floatValue = 10.0
              ..floatValueN = 10.0,
          ]),
        );
      });

      isarTest('min', () async {
        expect(await col.where().floatValueProperty().tMin(), -5.0);
        expect(await col.where().floatValueNProperty().tMin(), 10.0);

        expect(
          await col
              .where()
              .filter()
              .floatValueGreaterThan(9)
              .floatValueProperty()
              .tMin(),
          10.0,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .floatValueProperty()
              .tMin(),
          null,
        );
      });

      isarTest('max', () async {
        expect(await col.where().floatValueProperty().tMax(), 10.0);
        expect(await col.where().floatValueNProperty().tMax(), 10.0);

        expect(
          await col
              .where()
              .filter()
              .floatValueLessThan(-4)
              .floatValueProperty()
              .tMax(),
          -5.0,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .floatValueProperty()
              .tMax(),
          null,
        );
      });

      isarTest('sum', () async {
        expect(await col.where().floatValueProperty().tSum(), 5.0);
        expect(await col.where().floatValueNProperty().tSum(), 10.0);

        expect(
          await col
              .where()
              .filter()
              .floatValueGreaterThan(9)
              .floatValueProperty()
              .tSum(),
          10.0,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .floatValueProperty()
              .tSum(),
          0,
        );
      });

      isarTest('average', () async {
        expect(await col.where().floatValueProperty().tAverage(), 5 / 3);
        expect(await col.where().floatValueNProperty().tAverage(), 10.0);

        expect(
          await col
              .where()
              .filter()
              .floatValueGreaterThan(9)
              .floatValueProperty()
              .tAverage(),
          10.0,
        );

        expect(
          (await col
                  .where()
                  .filter()
                  .boolValueEqualTo(true)
                  .floatValueProperty()
                  .tAverage())
              .isNaN,
          true,
        );
      });

      isarTest('count', () async {
        expect(await col.where().floatValueProperty().tCount(), 3);
        expect(await col.where().floatValueNProperty().tCount(), 3);

        expect(
          await col
              .where()
              .filter()
              .floatValueGreaterThan(9)
              .floatValueProperty()
              .tCount(),
          1,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .floatValueProperty()
              .tCount(),
          0,
        );
      });
    });

    group('long', () {
      setUp(() async {
        await isar.writeTxn(
          () => col.putAll([
            MultiTypeModel()..longValue = -5,
            MultiTypeModel()..longValue = 0,
            MultiTypeModel()
              ..longValue = 10
              ..longValueN = 10,
          ]),
        );
      });

      isarTest('min', () async {
        expect(await col.where().longValueProperty().tMin(), -5);
        expect(await col.where().longValueNProperty().tMin(), 10);

        expect(
          await col
              .where()
              .filter()
              .longValueEqualTo(10)
              .longValueProperty()
              .tMin(),
          10,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .longValueProperty()
              .tMin(),
          null,
        );
      });

      isarTest('max', () async {
        expect(await col.where().longValueProperty().tMax(), 10);
        expect(await col.where().longValueNProperty().tMax(), 10);

        expect(
          await col
              .where()
              .filter()
              .longValueEqualTo(-5)
              .longValueProperty()
              .tMax(),
          -5,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .longValueProperty()
              .tMax(),
          null,
        );
      });

      isarTest('sum', () async {
        expect(await col.where().longValueProperty().tSum(), 5);
        expect(await col.where().longValueNProperty().tSum(), 10);

        expect(
          await col
              .where()
              .filter()
              .longValueEqualTo(10)
              .longValueProperty()
              .tSum(),
          10,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .longValueProperty()
              .tSum(),
          0,
        );
      });

      isarTest('average', () async {
        expect(await col.where().longValueProperty().tAverage(), 5 / 3);
        expect(await col.where().longValueNProperty().tAverage(), 10);

        expect(
          await col
              .where()
              .filter()
              .longValueEqualTo(10)
              .longValueProperty()
              .tAverage(),
          10.0,
        );

        expect(
          (await col
                  .where()
                  .filter()
                  .boolValueEqualTo(true)
                  .longValueProperty()
                  .tAverage())
              .isNaN,
          true,
        );
      });

      isarTest('count', () async {
        expect(await col.where().longValueProperty().tCount(), 3);
        expect(await col.where().longValueNProperty().tCount(), 3);

        expect(
          await col
              .where()
              .filter()
              .longValueEqualTo(10)
              .longValueProperty()
              .tCount(),
          1,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .longValueProperty()
              .tCount(),
          0,
        );
      });
    });

    group('double', () {
      setUp(() async {
        await isar.writeTxn(
          () => col.putAll([
            MultiTypeModel()..doubleValue = -5.0,
            MultiTypeModel()..doubleValue = 0.0,
            MultiTypeModel()
              ..doubleValue = 10.0
              ..doubleValueN = 10.0,
          ]),
        );
      });

      isarTest('min', () async {
        expect(await col.where().doubleValueProperty().tMin(), -5.0);
        expect(await col.where().doubleValueNProperty().tMin(), 10.0);

        expect(
          await col
              .where()
              .filter()
              .doubleValueGreaterThan(9)
              .doubleValueProperty()
              .tMin(),
          10.0,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .doubleValueProperty()
              .tMin(),
          null,
        );
      });

      isarTest('max', () async {
        expect(await col.where().doubleValueProperty().tMax(), 10.0);
        expect(await col.where().doubleValueNProperty().tMax(), 10.0);

        expect(
          await col
              .where()
              .filter()
              .doubleValueLessThan(-4)
              .doubleValueProperty()
              .tMax(),
          -5.0,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .doubleValueProperty()
              .tMax(),
          null,
        );
      });

      isarTest('sum', () async {
        expect(await col.where().doubleValueProperty().tSum(), 5.0);
        expect(await col.where().doubleValueNProperty().tSum(), 10.0);

        expect(
          await col
              .where()
              .filter()
              .doubleValueGreaterThan(9)
              .doubleValueProperty()
              .tSum(),
          10.0,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .doubleValueProperty()
              .tSum(),
          0,
        );
      });

      isarTest('average', () async {
        expect(await col.where().doubleValueProperty().tAverage(), 5 / 3);
        expect(await col.where().doubleValueNProperty().tAverage(), 10.0);

        expect(
          await col
              .where()
              .filter()
              .doubleValueGreaterThan(9)
              .doubleValueProperty()
              .tAverage(),
          10.0,
        );

        expect(
          (await col
                  .where()
                  .filter()
                  .boolValueEqualTo(true)
                  .doubleValueProperty()
                  .tAverage())
              .isNaN,
          true,
        );
      });

      isarTest('count', () async {
        expect(await col.where().doubleValueProperty().tCount(), 3);
        expect(await col.where().doubleValueNProperty().tCount(), 3);

        expect(
          await col
              .where()
              .filter()
              .doubleValueGreaterThan(9)
              .doubleValueProperty()
              .tCount(),
          1,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .doubleValueProperty()
              .tCount(),
          0,
        );
      });
    });

    group('DateTime', () {
      DateTime date(int milliseconds) =>
          DateTime.fromMillisecondsSinceEpoch(milliseconds);

      setUp(() async {
        await isar.writeTxn(
          () => col.putAll([
            MultiTypeModel()..dateTimeValue = date(-5),
            MultiTypeModel()..dateTimeValue = date(0),
            MultiTypeModel()
              ..dateTimeValue = date(10)
              ..dateTimeValueN = date(10),
          ]),
        );
      });

      isarTest('min', () async {
        expect(await col.where().dateTimeValueProperty().tMin(), date(-5));
        expect(await col.where().dateTimeValueNProperty().tMin(), date(10));

        expect(
          await col
              .where()
              .filter()
              .dateTimeValueEqualTo(date(10))
              .dateTimeValueProperty()
              .tMin(),
          date(10),
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .dateTimeValueProperty()
              .tMin(),
          null,
        );
      });

      isarTest('max', () async {
        expect(await col.where().dateTimeValueProperty().tMax(), date(10));
        expect(await col.where().dateTimeValueNProperty().tMax(), date(10));

        expect(
          await col
              .where()
              .filter()
              .dateTimeValueEqualTo(date(-5))
              .dateTimeValueProperty()
              .tMax(),
          date(-5),
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .dateTimeValueProperty()
              .tMax(),
          null,
        );
      });

      isarTest('count', () async {
        expect(await col.where().dateTimeValueProperty().tCount(), 3);
        expect(await col.where().dateTimeValueNProperty().tCount(), 3);

        expect(
          await col
              .where()
              .filter()
              .dateTimeValueEqualTo(date(10))
              .dateTimeValueProperty()
              .tCount(),
          1,
        );

        expect(
          await col
              .where()
              .filter()
              .boolValueEqualTo(true)
              .dateTimeValueProperty()
              .tCount(),
          0,
        );
      });
    });
  });
}
