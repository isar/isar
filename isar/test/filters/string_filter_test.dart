import 'package:test/test.dart';

import '../common.dart';
import '../isar.g.dart';
import '../models/string_model.dart';

void main() {
  group('String filter', () {
    Isar isar;
    late IsarCollection<int, StringModel> col;

    setUp(() async {
      setupIsar();

      final dir = await getTempDir();
      isar = await openIsar(directory: dir.path);
      col = isar.stringModels;

      await isar.writeTxn((isar) async {
        for (var i = 0; i < 5; i++) {
          final obj = StringModel()..field = 'string_$i';
          await col.put(obj);
        }
        await col.put(StringModel()..field = null);
        await col.put(StringModel()..field = '');
      });
    });

    test('equalTo()', () async {
      await qEqual(
        col.where().fieldEqualTo('string_2').findAll(),
        [StringModel()..field = 'string_2'],
      );
      await qEqual(
        col.where().filter().fieldEqualTo('string_2').findAll(),
        [StringModel()..field = 'string_2'],
      );

      await qEqual(
        col.where().fieldEqualTo(null).findAll(),
        [StringModel()..field = null],
      );
      await qEqual(
        col.where().filter().fieldEqualTo(null).findAll(),
        [StringModel()..field = null],
      );

      await qEqual(
        col.where().fieldEqualTo('string_5').findAll(),
        [],
      );
      await qEqual(
        col.where().filter().fieldEqualTo('string_5').findAll(),
        [],
      );
    });
  });
}
