import 'common.dart';
import 'isar.g.dart';
import 'models/bool_model.dart';
import 'models/double_model.dart';

void main() async {
  setupIsar();

  final dir = await getTempDir();
  final isar = await openIsar(directory: dir.path);
  final col = isar.doubleModels;

  await isar.writeTxn((isar) async {
    for (var i = 0; i < 5; i++) {
      final obj = DoubleModel()..field = i.toDouble() + i.toDouble() / 10;
      await col.put(obj);
    }
    await col.put(DoubleModel()..field = null);
  });

  assert(
    await col.where().fieldGreaterThan(3.3).findAll() ==
        [DoubleModel()..field = 4.4],
  );

  assert(
    await col.where().fieldGreaterThan(3.3, include: true).findAll() ==
        [DoubleModel()..field = 3.3, DoubleModel()..field = 4.4],
  );

  assert(
    await col.where().fieldGreaterThan(4.4).findAll() == [],
  );
}
