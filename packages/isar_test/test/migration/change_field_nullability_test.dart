import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'change_field_nullability_test.g.dart';

@collection
@Name('Col')
class Col1 {
  Col1(this.id, this.value);

  int id;

  String? value;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is Col1 && id == other.id && value == other.value;
}

@collection
@Name('Col')
class Col2 {
  Col2(this.id, this.value);

  int id;

  late String value;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is Col2 && id == other.id && value == other.value;
}

void main() {
  isarTest('Change field nullability', web: false, () async {
    final isar1 = await openTempIsar([Col1Schema]);
    final isarName = isar1.name;
    isar1.write((isar) {
      return isar1.col1s.putAll([Col1(1, 'a'), Col1(2, null)]);
    });
    expect(isar1.close(), true);

    final isar2 = await openTempIsar([Col2Schema], name: isarName);
    expect(isar2.col2s.where().findAll(), [Col2(1, 'a'), Col2(2, '')]);
    isar2.write((isar) {
      return isar2.col2s.put(Col2(1, 'c'));
    });
    expect(isar2.close(), true);

    final isar3 = await openTempIsar([Col1Schema], name: isarName);
    expect(isar3.col1s.where().findAll(), [Col1(1, 'c'), Col1(2, null)]);
  });
}
