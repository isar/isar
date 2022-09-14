import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'is_empty_is_not_empty_test.g.dart';

@collection
class Model {
  Model(this.value);

  Id id = Isar.autoIncrement;

  String? value;
}

void main() {
  group('Query isEmpty / isNotEmpty', () {
    late Isar isar;

    setUp(() async {
      isar = await openTempIsar([ModelSchema]);

      await isar.tWriteTxn(
        () => isar.models.tPutAll(List.generate(100, (i) => Model('model $i'))),
      );
    });

    isarTest('.isEmpty()', () async {
      expect(await isar.models.where().tIsEmpty(), false);
      expect(await isar.models.where().limit(999999).tIsEmpty(), false);
      expect(await isar.models.where().limit(1).tIsEmpty(), false);
      expect(await isar.models.where().limit(0).tIsEmpty(), true);

      expect(
        await isar.models.filter().valueStartsWith('model').tIsEmpty(),
        false,
      );
      expect(
        await isar.models.filter().valueEqualTo('model 1').tIsEmpty(),
        false,
      );
      expect(
        await isar.models.filter().valueStartsWith('non existing').tIsEmpty(),
        true,
      );
      expect(
        await isar.models
            .filter()
            .valueStartsWith('model 1')
            .and()
            .valueEqualTo('model 2')
            .tIsEmpty(),
        true,
      );
      expect(
        await isar.models
            .filter()
            .valueEqualTo('model 1')
            .or()
            .valueEqualTo('model 2')
            .tIsEmpty(),
        false,
      );

      await isar.tWriteTxn(() => isar.models.where().limit(99).tDeleteAll());

      expect(await isar.models.where().tIsEmpty(), false);
      expect(await isar.models.where().limit(999999).tIsEmpty(), false);
      expect(await isar.models.where().limit(1).tIsEmpty(), false);
      expect(await isar.models.where().limit(0).tIsEmpty(), true);

      await isar.tWriteTxn(() => isar.models.where().tDeleteAll());

      expect(await isar.models.where().tIsEmpty(), true);
      expect(await isar.models.where().limit(999999).tIsEmpty(), true);
      expect(await isar.models.where().limit(1).tIsEmpty(), true);
      expect(await isar.models.where().limit(0).tIsEmpty(), true);

      await isar.tWriteTxn(() => isar.models.tPut(Model(null)));

      expect(await isar.models.where().tIsEmpty(), false);
      expect(await isar.models.where().limit(999999).tIsEmpty(), false);
      expect(await isar.models.where().limit(1).tIsEmpty(), false);
      expect(await isar.models.where().limit(0).tIsEmpty(), true);
    });

    isarTest('.isNotEmpty()', () async {
      expect(await isar.models.where().tIsNotEmpty(), true);
      expect(await isar.models.where().limit(999999).tIsNotEmpty(), true);
      expect(await isar.models.where().limit(1).tIsNotEmpty(), true);
      expect(await isar.models.where().limit(0).tIsNotEmpty(), false);

      expect(
        await isar.models.filter().valueStartsWith('model').tIsNotEmpty(),
        true,
      );
      expect(
        await isar.models.filter().valueEqualTo('model 1').tIsNotEmpty(),
        true,
      );
      expect(
        await isar.models
            .filter()
            .valueStartsWith('non existing')
            .tIsNotEmpty(),
        false,
      );
      expect(
        await isar.models
            .filter()
            .valueStartsWith('model 1')
            .and()
            .valueEqualTo('model 2')
            .tIsNotEmpty(),
        false,
      );
      expect(
        await isar.models
            .filter()
            .valueEqualTo('model 1')
            .or()
            .valueEqualTo('model 2')
            .tIsNotEmpty(),
        true,
      );

      await isar.tWriteTxn(() => isar.models.where().limit(99).tDeleteAll());

      expect(await isar.models.where().tIsNotEmpty(), true);
      expect(await isar.models.where().limit(999999).tIsNotEmpty(), true);
      expect(await isar.models.where().limit(1).tIsNotEmpty(), true);
      expect(await isar.models.where().limit(0).tIsNotEmpty(), false);

      await isar.tWriteTxn(() => isar.models.where().tDeleteAll());

      expect(await isar.models.where().tIsNotEmpty(), false);
      expect(await isar.models.where().limit(999999).tIsNotEmpty(), false);
      expect(await isar.models.where().limit(1).tIsNotEmpty(), false);
      expect(await isar.models.where().limit(0).tIsNotEmpty(), false);

      await isar.tWriteTxn(() => isar.models.tPut(Model(null)));

      expect(await isar.models.where().tIsNotEmpty(), true);
      expect(await isar.models.where().limit(999999).tIsNotEmpty(), true);
      expect(await isar.models.where().limit(1).tIsNotEmpty(), true);
      expect(await isar.models.where().limit(0).tIsNotEmpty(), false);
    });
  });
}
