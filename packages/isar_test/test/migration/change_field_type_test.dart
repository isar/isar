@TestOn('vm')

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';

part 'change_field_type_test.g.dart';

@Collection()
@Name('Col')
class Col1 {
  int? id;

  String? value;

  Col1(this.id, this.value);
}

@Collection()
@Name('Col')
class Col2 {
  int? id;

  int? value;
}

void main() {
  testSyncAsync(tests);
}

void tests() {
  isarTest('Change field type', () async {
    final isar1 = await openTempIsar([Col1Schema]);
    await isar1.tWriteTxn(() {
      return isar1.col1s.tPut(Col1(1, 'a'));
    });
    expect(await isar1.close(), true);
    await expectLater(
      () => openTempIsar([Col2Schema], name: isar1.name),
      throwsIsarError('SchemaError'),
    );
  });
}
