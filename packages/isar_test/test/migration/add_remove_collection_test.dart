import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';

part 'add_remove_collection_test.g.dart';

@Collection()
class Col1 {
  Col1(this.id, this.value);
  Id? id;

  String? value;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is Col1 && id == other.id && value == other.value;
}

@Collection()
class Col2 {
  Col2(this.id, this.value);
  Id? id;

  String? value;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is Col2 && id == other.id && value == other.value;
}

void main() {
  isarTest('Add collection', () async {
    final isar1 = await openTempIsar([Col1Schema]);
    final col1A = Col1(5, 'col1_a');
    final col1B = Col1(15, 'col1_b');
    await isar1.tWriteTxn(() {
      return isar1.col1s.tPutAll([col1A, col1B]);
    });
    expect(await isar1.close(), true);

    final isar2 =
        await openTempIsar([Col1Schema, Col2Schema], name: isar1.name);
    await qEqual(isar2.col1s.where().tFindAll(), [col1A, col1B]);
    await qEqual(isar2.col2s.where().tFindAll(), []);
    await isar2.tWriteTxn(() {
      return isar2.col2s.tPut(Col2(null, 'col2_a'));
    });
    await qEqual(isar2.col2s.where().tFindAll(), [Col2(1, 'col2_a')]);
    expect(await isar2.close(), true);
  });

  isarTest('Remove collection', () async {
    final isar1 = await openTempIsar([Col1Schema, Col2Schema]);
    final col1A = Col1(5, 'col1_a');
    final col1B = Col1(15, 'col1_b');
    await isar1.writeTxn(() async {
      await isar1.col1s.putAll([col1A, col1B]);
      await isar1.col2s.put(Col2(100, 'col2_a'));
    });
    expect(await isar1.close(), true);

    final isar2 = await openTempIsar([Col1Schema], name: isar1.name);
    await qEqual(isar2.col1s.where().findAll(), [col1A, col1B]);
    expect(await isar2.close(), true);

    final isar3 =
        await openTempIsar([Col1Schema, Col2Schema], name: isar1.name);
    await qEqual(isar3.col1s.where().findAll(), [col1A, col1B]);
    await qEqual(isar3.col2s.where().findAll(), []);
    expect(await isar3.close(), true);
  });
}
