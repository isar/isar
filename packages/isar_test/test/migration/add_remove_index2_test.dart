import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'add_remove_index2_test.g.dart';

@collection
@Name('Col')
class Col1 {
  Col1(this.id, this.value);
  Id? id;

  @Index()
  int? value;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is Col1 && id == other.id && value == other.value;
}

@collection
@Name('Col')
class Col2 {
  Col2(this.id, this.other);
  Id? id;

  @Index()
  List<int>? other;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is Col2 && id == other.id && listEquals(this.other, other.other);
}

void main() {
  isarTest('Add remove index', () async {
    final isar1 = await openTempIsar([Col1Schema]);
    await isar1.tWriteTxn(() {
      return isar1.col1s.tPutAll([Col1(1, 1), Col1(2, 2)]);
    });
    expect(await isar1.close(), true);

    final isar2 = await openTempIsar([Col2Schema], name: isar1.name);
    await qEqual(isar2.col2s.where(), [Col2(1, []), Col2(2, null)]);

    expect(await isar2.close(), true);
  });
}
