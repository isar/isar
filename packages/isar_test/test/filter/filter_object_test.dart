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
      other is ObjectModel && other.id == id && field == other.field;
}

@embedded
class EmbeddedModel {
  EmbeddedModel([this.value, this.embedded]);

  String? value;

  EmbeddedModel? embedded;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is EmbeddedModel &&
      other.value == value &&
      embedded == other.embedded;
}

void main() {
  group('Object filter filter', () {
    late Isar isar;
    late IsarCollection<ObjectModel> col;

    late ObjectModel obj0;
    late ObjectModel obj1;
    late ObjectModel obj2;
    late ObjectModel objE0;
    late ObjectModel objE1;
    late ObjectModel objE2;
    late ObjectModel objENull;
    late ObjectModel objNull;

    setUp(() async {
      isar = await openTempIsar([ObjectModelSchema]);
      col = isar.objectModels;

      objNull = ObjectModel(null);
      objENull = ObjectModel(EmbeddedModel());
      obj0 = ObjectModel(EmbeddedModel('test'));
      obj1 = ObjectModel(EmbeddedModel('test1'));
      obj2 = ObjectModel(EmbeddedModel('test2'));
      objE0 = ObjectModel(EmbeddedModel('embedded', EmbeddedModel('test')));
      objE1 = ObjectModel(EmbeddedModel('embedded1', EmbeddedModel('test1')));
      objE2 = ObjectModel(EmbeddedModel('embedded2', EmbeddedModel('test2')));

      await isar.writeTxn(() async {
        await isar.objectModels
            .putAll([obj0, obj1, obj2, objE0, objE1, objE2, objENull, objNull]);
      });
    });

    isarTest('simple conditions', () async {
      await qEqual(
        col.filter().field((q) => q.valueContains('test')),
        [obj0, obj1, obj2],
      );
      await qEqual(
        col.filter().field((q) => q.not().valueContains('test')),
        [obj3, objENull],
      );
      await qEqual(col.filter().field((q) => q.valueIsNull()), [objENull]);
      await qEqual(col.filter().field((q) => q.valueEndsWith('4')), []);
    });

    isarTest('multiple conditions', () async {
      await qEqual(
        col
            .filter()
            .field((q) => q.valueContains('test'))
            .field((q) => q.not().valueContains('1')),
        [obj0, obj2],
      );
    });

    isarTest('.isNull()', () async {
      await qEqual(col.filter().fieldIsNull(), [objNull]);
    });
  });
}
