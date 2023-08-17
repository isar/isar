import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'is_empty_test.g.dart';

@collection
class Model {
  Model(this.id, this.value);

  final int id;

  final String? value;
}

void main() {
  group('Query isEmpty / isNotEmpty', () {
    late Isar isar;

    setUp(() async {
      isar = await openTempIsar([ModelSchema]);

      isar.write(
        (isar) => isar.models.putAll(
          List.generate(100, (i) => Model(i, 'model $i')),
        ),
      );
    });

    isarTest('.isEmpty()', () {
      expect(isar.models.where().isEmpty(), false);
      expect(
        isar.models.where().valueStartsWith('model').isEmpty(),
        false,
      );
      expect(
        isar.models.where().valueEqualTo('model 1').isEmpty(),
        false,
      );
      expect(
        isar.models.where().valueStartsWith('non existing').isEmpty(),
        true,
      );
      expect(
        isar.models
            .where()
            .valueStartsWith('model 1')
            .and()
            .valueEqualTo('model 2')
            .isEmpty(),
        true,
      );
      expect(
        isar.models
            .where()
            .valueEqualTo('model 1')
            .or()
            .valueEqualTo('model 2')
            .isEmpty(),
        false,
      );

      isar.write((isar) => isar.models.where().deleteAll(limit: 99));
      expect(isar.models.where().isEmpty(), false);

      isar.write((isar) => isar.models.where().deleteAll());
      expect(isar.models.where().isEmpty(), true);

      isar.write((isar) => isar.models.put(Model(0, null)));
      expect(isar.models.where().isEmpty(), false);
    });
  });
}
