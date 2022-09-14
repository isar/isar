@TestOn('vm')

import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'change_field_type_test.g.dart';

@collection
@Name('Col')
class Model1 {
  Model1(this.id, this.value, this.str);

  Id? id;

  @Index()
  @Index(composite: [CompositeIndex('str')])
  String? value;

  @Index(composite: [CompositeIndex('value')])
  String str;
}

@collection
@Name('Col')
class Model2 {
  Model2(this.id, this.value, this.str);

  Id? id;

  @Index()
  @Index(composite: [CompositeIndex('str')])
  int? value;

  @Index(composite: [CompositeIndex('value')])
  String str;
}

void main() {
  isarTest('Change field type', () async {
    final isar1 = await openTempIsar([Model1Schema]);
    final obj1A = Model1(1, 'a', 'OBJ1');
    final obj1B = Model1(2, 'bbb', 'OBJ2');
    await isar1.tWriteTxn(() {
      return isar1.model1s.tPutAll([obj1A, obj1B]);
    });
    expect(await isar1.close(), true);

    final isar2 = await openTempIsar([Model2Schema], name: isar1.name);
    final obj2A = Model2(1, null, 'OBJ1');
    final obj2B = Model2(2, null, 'OBJ2');
    await isar2.model2s.verify([obj2A, obj2B]);
    final obj2C = Model2(1, 123, 'OBJ3');
    await isar2.tWriteTxn(() {
      return isar2.model2s.tPut(obj2C);
    });
    await isar2.model2s.verify([obj2C, obj2B]);
  });
}
