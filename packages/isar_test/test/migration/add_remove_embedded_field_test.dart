import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'add_remove_embedded_field_test.g.dart';

@collection
@Name('Col')
class Col1 {
  Col1(this.id, this.value);

  int id;

  Embedded1? value;

  @override
  bool operator ==(Object other) =>
      other is Col1 && id == other.id && value == other.value;
}

@embedded
@Name('Embedded')
class Embedded1 {
  Embedded1([this.value]);

  String? value;

  @override
  bool operator ==(Object other) => other is Embedded1 && value == other.value;
}

@collection
@Name('Col')
class Col2 {
  Col2(this.id, this.value);

  int id;

  Embedded2? value;

  @override
  bool operator ==(Object other) =>
      other is Col2 && id == other.id && value == other.value;
}

@embedded
@Name('Embedded')
class Embedded2 {
  Embedded2([this.newValue, this.value]);

  int? newValue;

  String? value;

  @override
  bool operator ==(Object other) =>
      other is Embedded2 && value == other.value && newValue == other.newValue;
}

void main() {
  isarTest('Add field', web: false, () async {
    final isar1 = await openTempIsar([Col1Schema]);
    final isarName = isar1.name;
    isar1.write((isar) {
      return isar.col1s.putAll([
        Col1(1, Embedded1('value1')),
        Col1(2, Embedded1('value2')),
      ]);
    });
    expect(isar1.close(), true);

    final isar2 = await openTempIsar([Col2Schema], name: isarName);
    isar2.col2s.verify([
      Col2(1, Embedded2(null, 'value1')),
      Col2(2, Embedded2(null, 'value2')),
    ]);
    isar2.write((isar) {
      return isar.col2s.putAll([
        Col2(1, Embedded2(1, 'value4')),
        Col2(3, Embedded2(3, 'value5')),
      ]);
    });
    isar2.col2s.verify([
      Col2(1, Embedded2(1, 'value4')),
      Col2(2, Embedded2(null, 'value2')),
      Col2(3, Embedded2(3, 'value5')),
    ]);
    expect(isar2.close(), true);

    final isar3 = await openTempIsar([Col1Schema], name: isarName);
    isar3.col1s.verify([
      Col1(1, Embedded1('value4')),
      Col1(2, Embedded1('value2')),
      Col1(3, Embedded1('value5')),
    ]);
    expect(isar3.close(), true);
  });

  /*isarTest('Remove field', () async {
    final isar1 = await await openTempIsar([Col2Schema]);
    await isar1.write(() {
      return isar1.col2s.putAll([
        Col2(1, 'value1', ['hi']),
        Col2(2, 'value2', ['val2', 'val22']),
      ]);
    });
    expect(await isar1.close(), true);

    final isar2 = await await openTempIsar([Col1Schema], name: isar1.name);
    await expect(isar2.col1s.where(), [
      Col1(1, 'value1'),
      Col1(2, 'value2'),
    ]);
    await isar2.write(() {
      return isar2.col1s.put(Col1(1, 'value3'));
    });
    await expect(isar2.col1s.where(), [
      Col1(1, 'value3'),
      Col1(2, 'value2'),
    ]);
    expect(await isar2.close(), true);
  });*/
}
