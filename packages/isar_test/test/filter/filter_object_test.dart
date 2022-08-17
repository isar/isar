import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';

part 'filter_object_test.g.dart';

@collection
class ObjectModel {
  ObjectModel(this.field);

  Id? id;

  EmbeddedModel? field;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is ObjectModel &&
      other.id == id &&
      (field == null) == (other.field == null) &&
      field?.value == other.field?.value;
}

@embedded
class EmbeddedModel {
  EmbeddedModel([this.value]);

  String? value;
}

void main() {
  group('Object filter filter', () {
    late Isar isar;
    late IsarCollection<ObjectModel> col;

    late ObjectModel obj0;
    late ObjectModel obj1;
    late ObjectModel obj2;
    late ObjectModel obj3;
    late ObjectModel objENull;
    late ObjectModel objNull;

    setUp(() async {
      isar = await openTempIsar([ObjectModelSchema]);
      col = isar.objectModels;

      objNull = ObjectModel(null);
      objENull = ObjectModel(EmbeddedModel(null));
      obj0 = ObjectModel(EmbeddedModel('test'));
      obj1 = ObjectModel(EmbeddedModel('test1'));
      obj2 = ObjectModel(EmbeddedModel('test3'));
      obj3 = ObjectModel(EmbeddedModel('hello'));

      await isar.writeTxn(() async {
        await isar.objectModels
            .putAll([obj0, obj1, obj2, obj3, objENull, objNull]);
      });
    });
  });
}
