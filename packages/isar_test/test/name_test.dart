import 'package:isar/isar.dart';
import 'package:test/test.dart';

import 'common.dart';

part 'name_test.g.dart';

@Collection()
@Name('NameModelN')
class NameModel {
  @Id()
  @Name('idN')
  int? id;

  @Index()
  @Name('valueN')
  String? value;

  @Index(composite: [CompositeIndex('value')])
  @Name('otherValueN')
  String? otherValue;

  @Name('linkN')
  var link = IsarLinks<NameModel>();

  @Backlink(to: 'link')
  @Name('backlink')
  var backlink = IsarLinks<NameModel>();
}

void main() {
  group('Name', () {
    late Isar isar;

    setUp(() async {
      isar = await openTempIsar([NameModelSchema]);
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('json', () async {
      await isar.writeTxn((isar) => isar.nameModels.put(
            NameModel()
              ..value = 'test'
              ..otherValue = 'test2',
          ));

      expect(await isar.nameModels.where().exportJson(), [
        {
          'idN': 1,
          'valueN': 'test',
          'otherValueN': 'test2',
        },
      ]);
    });
  });
}
