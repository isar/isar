import 'package:isar/isar.dart';

part 'add_remove_index_test.g.dart';

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

  @Index(unique: true)
  String? value;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is Col2 && id == other.id && value == other.value;
}

void main() {
  /*isarTest('Add remove index', () {
    final isar1 = await openTempIsar([Col1Schema]);
    final isarName = isar1.name;
    isar1.write((isar) {
      return isar.col1s.putAll([Col1(1, 'a'), Col1(2, 'b')]);
    });
    expect(isar1.close(), true);

    final isar2 = await openTempIsar([Col2Schema], name: isarName);
    expect(isar2.col2s.where().findAll(), [Col2(1, 'a'), Col2(2, 'b')]);
    /*expect(await isar2.col2s.getByValue('a'), Col2(1, 'a'));
     isar2.write((isar) {
      return isar2.col2s.putAll([Col2(1, 'c'), Col2(3, 'd')]);
    });*/
    expect(isar2.close(), true);

    final isar3 = await openTempIsar([Col1Schema], name: isarName);
    expect(isar3.col1s.where().findAll(), [
      Col1(1, 'c'),
      Col1(2, 'b'),
      Col1(3, 'd'),
    ]);
  });*/
}
