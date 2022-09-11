import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'add_remove_collection_test.g.dart';

@collection
class Model1 {
  Model1(this.id, this.value);

  Id? id;

  @Index()
  String? value;

  final link = IsarLink<Model1>();

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is Model1 && id == other.id && value == other.value;
}

@collection
class Model2 {
  Model2(this.id, this.value);

  Id? id;

  @Index()
  String? value;

  final link = IsarLink<Model1>();

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is Model2 && id == other.id && value == other.value;
}

void main() {
  isarTest('Add collection', () async {
    final isar1 = await openTempIsar([Model1Schema]);
    final obj1A = Model1(5, 'col1_a');
    final obj1B = Model1(15, 'col1_b');
    await isar1.tWriteTxn(() {
      return isar1.model1s.tPutAll([obj1A, obj1B]);
    });
    await isar1.model1s.verify([obj1A, obj1B]);
    expect(await isar1.close(), true);

    final isar2 =
        await openTempIsar([Model1Schema, Model2Schema], name: isar1.name);
    await isar2.model1s.verify([obj1A, obj1B]);
    await isar2.model2s.verify([]);
    final obj2 = Model2(null, 'col2_a');
    await isar2.tWriteTxn(() {
      return isar2.model2s.tPut(obj2);
    });
    await isar2.model2s.verify([obj2]);
  });

  isarTest('Remove collection', () async {
    final isar1 = await openTempIsar([Model1Schema, Model2Schema]);
    final obj1A = Model1(5, 'col1_a');
    final obj1B = Model1(15, 'col1_b');
    final obj2A = Model2(15, 'col2_a');
    final obj2B = Model2(15, 'col2_a');
    await isar1.tWriteTxn(() async {
      await isar1.model1s.tPutAll([obj1A, obj1B]);
      await isar1.model2s.tPutAll([obj2A, obj2B]);

      obj1A.link.value = obj1B;
      await obj1A.link.tSave();

      obj2A.link.value = obj1A;
      await obj2A.link.tSave();
    });
    await isar1.model1s.verify([obj1A, obj1B]);
    await isar1.model1s.verifyLink('link', [obj1A.id!], [obj1B.id!]);
    await isar1.model2s.verify([obj2A, obj2B]);
    await isar1.model2s.verifyLink('link', [obj2A.id!], [obj1A.id!]);
    expect(await isar1.close(), true);

    final isar2 = await openTempIsar([Model1Schema], name: isar1.name);
    await isar2.model1s.verify([obj1A, obj1B]);
    await isar2.model1s.verifyLink('link', [obj1A.id!], [obj1B.id!]);
    expect(await isar2.close(), true);

    final isar3 = await openTempIsar(
      [Model1Schema, Model2Schema],
      name: isar1.name,
    );
    await isar3.model1s.verify([obj1A, obj1B]);
    await isar3.model1s.verifyLink('link', [obj1A.id!], [obj1B.id!]);
    await isar3.model2s.verify([]);
    await isar3.model2s.verifyLink('link', [], []);
  });
}
