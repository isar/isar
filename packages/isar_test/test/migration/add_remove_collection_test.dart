import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'add_remove_collection_test.g.dart';

@collection
class Model1 {
  Model1(this.id, this.value);

  int id;

  @Index()
  String? value;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is Model1 && id == other.id && value == other.value;
}

@collection
class Model2 {
  Model2(this.id, this.value);

  int id;

  @Index()
  String? value;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is Model2 && id == other.id && value == other.value;
}

void main() {
  isarTest('Add collection', web: false, () async {
    final isar1 = await openTempIsar([Model1Schema]);
    final isarName = isar1.name;
    final obj1A = Model1(5, 'col1_a');
    final obj1B = Model1(15, 'col1_b');
    isar1.write((isar) {
      return isar.model1s.putAll([obj1A, obj1B]);
    });
    isar1.model1s.verify([obj1A, obj1B]);
    expect(isar1.close(), true);

    final isar2 =
        await openTempIsar([Model1Schema, Model2Schema], name: isarName);
    isar2.model1s.verify([obj1A, obj1B]);
    isar2.model2s.verify([]);
    final obj2 = Model2(99, 'col2_a');
    isar2.write((isar) {
      return isar.model2s.put(obj2);
    });
    isar2.model2s.verify([obj2]);
  });

  isarTest('Remove collection', web: false, () async {
    final isar1 = await openTempIsar([Model1Schema, Model2Schema]);
    final isarName = isar1.name;
    final obj1A = Model1(1, 'col1_a');
    final obj1B = Model1(2, 'col1_b');
    final obj2A = Model2(3, 'col2_a');
    final obj2B = Model2(4, 'col2_a');
    isar1.write((isar) {
      isar.model1s.putAll([obj1A, obj1B]);
      isar.model2s.putAll([obj2A, obj2B]);
    });
    isar1.model1s.verify([obj1A, obj1B]);
    isar1.model2s.verify([obj2A, obj2B]);
    expect(isar1.close(), true);

    final isar2 = await openTempIsar([Model1Schema], name: isarName);
    isar2.model1s.verify([obj1A, obj1B]);
    expect(isar2.close(), true);

    final isar3 =
        await openTempIsar([Model1Schema, Model2Schema], name: isarName);
    isar3.model1s.verify([obj1A, obj1B]);
    isar3.model2s.verify([]);
  });
}
