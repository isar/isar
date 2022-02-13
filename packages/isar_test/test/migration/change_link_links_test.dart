import 'package:isar/isar.dart';
import 'package:isar_test/common.dart';
import 'package:test/test.dart';

part 'change_link_links_test.g.dart';

@Collection()
@Name('Col')
class Col1 {
  int? id;

  final link = IsarLink<Col1>();

  Col1(this.id);

  @override
  operator ==(other) => other is Col1 && id == other.id;
}

@Collection()
@Name('Col')
class Col2 {
  int? id;

  final link = IsarLinks<Col2>();

  Col2(this.id);

  @override
  operator ==(other) => other is Col2 && id == other.id;
}

void main() {
  isarTest('Add remove link', () async {
    final isar1 = await openTempIsar([Col1Schema]);
    await isar1.writeTxn((isar) async {
      final obj = Col1(1);
      obj.link.value = Col1(null);
      await isar.col1s.put(obj, saveLinks: true);
    });
    expect(await isar1.close(), true);

    final isar2 = await openTempIsar([Col2Schema], name: isar1.name);
    final obj = await isar2.col2s.get(1);
    await obj!.link.load();
    expect(obj.link, {Col2(2)});
    await isar2.writeTxn((isar) async {
      await obj.link.reset();
      obj.link.add(Col2(null));
      await obj.link.save();
    });
    expect(await isar2.close(), true);

    final isar3 = await openTempIsar([Col1Schema], name: isar1.name);
    final obj1 = await isar3.col1s.get(1);
    await obj1!.link.load();
    expect(obj1.link.value, Col1(3));
    expect(await isar3.close(), true);
  });
}
