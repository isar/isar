import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../common.dart';

part 'add_remove_collection_test.g.dart';

@Collection()
class Col1 {
  int? id;

  String? value;

  Col1(this.id, this.value);

  @override
  operator ==(other) => other is Col1 && id == other.id && value == other.value;
}

@Collection()
class Col2 {
  int? id;

  String? value;

  Col2(this.id, this.value);

  @override
  operator ==(other) => other is Col2 && id == other.id && value == other.value;
}

void main() {
  isarTest('Add collection', () async {
    final isar1 = await openTempIsar([Col1Schema]);
    final col1A = Col1(5, 'col1_a');
    final col1B = Col1(15, 'col1_b');
    await isar1.writeTxn((isar) {
      return isar.col1s.putAll([col1A, col1B]);
    });
    expect(await isar1.close(), true);

    final isar2 =
        await openTempIsar([Col1Schema, Col2Schema], name: isar1.name);
    await qEqual(isar2.col1s.where().findAll(), [col1A, col1B]);
    await qEqual(isar2.col2s.where().findAll(), []);
    await isar2.writeTxn((isar) {
      return isar.col2s.put(Col2(null, 'col2_a'));
    });
    await qEqual(isar2.col2s.where().findAll(), [Col2(1, 'col2_a')]);
    expect(await isar2.close(), true);
  });

  isarTest('Remove collection', () async {
    final isar1 = await openTempIsar([Col1Schema, Col2Schema]);
    final col1A = Col1(5, 'col1_a');
    final col1B = Col1(15, 'col1_b');
    await isar1.writeTxn((isar) async {
      await isar.col1s.putAll([col1A, col1B]);
      await isar.col2s.put(Col2(100, 'col2_a'));
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
