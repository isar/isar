import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'change_field_embedded_test.g.dart';

@collection
@Name('Col')
class Model1 {
  Model1(this.id, this.value);

  Id? id;

  Embedded1? value;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is Model1 && other.id == id && other.value == value;
}

@collection
@Name('Col')
class Model2 {
  Model2(this.id, this.value);

  Id? id;

  Embedded2? value;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is Model2 && other.id == id && other.value == value;
}

@embedded
class Embedded1 {
  Embedded1([this.value]);

  String? value;
}

@embedded
class Embedded2 {
  Embedded2([this.value]);

  String? value;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) => other is Embedded2 && other.value == value;
}

void main() {
  isarTest('Change field embedded', () async {
    final isar1 = await openTempIsar([Model1Schema]);
    await isar1.tWriteTxn(() {
      return isar1.model1s.tPutAll([
        Model1(1, Embedded1('a')),
        Model1(2, Embedded1('b')),
      ]);
    });
    expect(await isar1.close(), true);

    final isar2 = await openTempIsar([Model2Schema], name: isar1.name);
    await qEqual(isar2.model2s.where(), [
      Model2(1, null),
      Model2(2, null),
    ]);
    await isar2.tWriteTxn(() {
      return isar2.model2s.tPut(Model2(1, Embedded2('abc')));
    });
    expect(await isar2.close(), true);

    final isar3 = await openTempIsar([Model1Schema], name: isar1.name);
    await qEqual(isar3.model1s.where(), [
      Model1(1, null),
      Model1(2, null),
    ]);
  });
}
