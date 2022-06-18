import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';

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
  testSyncAsync(tests);
}

void tests() {
  isarTest('Add remove link', () async {
    final isar1 = await openTempIsar([Col1Schema]);
    await isar1.tWriteTxn(() async {
      final linkedObj = Col1(2);
      final obj = Col1(1);
      await isar1.col1s.tPutAll([obj, linkedObj]);

      obj.link.value = linkedObj;
      await obj.link.tSave();
    });
    expect(await isar1.close(), true);

    final isar2 = await openTempIsar([Col2Schema], name: isar1.name);
    final obj = await isar2.col2s.tGet(1);
    await obj!.link.tLoad();
    expect(obj.link, {Col2(2)});
    await isar2.tWriteTxn(() async {
      await obj.link.tReset();

      final obj3 = Col2(3);
      await isar2.col2s.tPut(obj3);

      obj.link.add(obj3);
      await obj.link.tSave();
    });
    expect(await isar2.close(), true);

    final isar3 = await openTempIsar([Col1Schema], name: isar1.name);
    final obj1 = await isar3.col1s.tGet(1);
    await obj1!.link.tLoad();
    expect(obj1.link.value, Col1(3));
    expect(await isar3.close(), true);
  });
}
