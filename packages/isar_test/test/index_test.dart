import 'package:isar/isar.dart';
import 'package:isar_test/src/common.dart';
import 'package:test/test.dart';

part 'index_test.g.dart';

@collection
class UniqueModel {
  UniqueModel({required this.id, this.value});

  final int id;

  @Index(unique: true)
  final String? value;

  @override
  bool operator ==(other) =>
      other is UniqueModel && id == other.id && value == other.value;
}

void main() {
  group('Index', () {
    late Isar isar;

    setUp(() async {
      isar = await openTempIsar([UniqueModelSchema]);
    });

    isarTest('unique values override each other', () {
      isar.write((isar) {
        isar.uniqueModels.putAll([
          UniqueModel(id: 1, value: 'a'),
          UniqueModel(id: 2, value: 'b'),
          UniqueModel(id: 3, value: 'c'),
          UniqueModel(id: 4, value: 'b'),
        ]);
      });

      expect(isar.uniqueModels.where().findAll(), [
        UniqueModel(id: 1, value: 'a'),
        UniqueModel(id: 3, value: 'c'),
        UniqueModel(id: 4, value: 'b'),
      ]);

      isar.write((isar) {
        isar.uniqueModels.put(UniqueModel(id: 5, value: 'a'));
      });
      expect(isar.uniqueModels.where().findAll(), [
        UniqueModel(id: 3, value: 'c'),
        UniqueModel(id: 4, value: 'b'),
        UniqueModel(id: 5, value: 'a'),
      ]);
    });

    isarTest('unique nulls do not override each other', () {
      isar.write((isar) {
        isar.uniqueModels.putAll([UniqueModel(id: 1), UniqueModel(id: 2)]);
      });

      expect(
        isar.uniqueModels.where().findAll(),
        [UniqueModel(id: 1), UniqueModel(id: 2)],
      );
    });
  });
}
