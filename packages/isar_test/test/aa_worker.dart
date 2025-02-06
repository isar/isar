import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';

import 'name_test.dart';

void main() async {
  print('HELLO WORKER');
  await Isar.initialize('http://localhost:3000');
  final isar = Isar.open(
    schemas: [NameModelSchema],
    name: 'test',
    directory: '',
    engine: IsarEngine.sqlite,
  );
  print('WORKER ISAR OPENED');
  isar.write((isar) {
    isar.nameModels.put(NameModel(4));
  });
  print('WORKER ISAR WRITTEN');
  print(isar.nameModels.where().findAll());
  print('WORKER ISAR READ');
}
