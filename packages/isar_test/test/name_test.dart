import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'name_test.g.dart';

@collection
@Name('NameModelN')
class NameModel {
  @Name('idN')
  Id? id;

  @Index()
  @Name('valueN')
  String? value;

  @Index(composite: [CompositeIndex('value')])
  @Name('otherValueN')
  String? otherValue;

  @Name('linkN')
  IsarLinks<NameModel> link = IsarLinks<NameModel>();

  @Backlink(to: 'link')
  @Name('backlink')
  IsarLinks<NameModel> backlink = IsarLinks<NameModel>();
}

void main() {
  group('Name', () {
    late Isar isar;

    setUp(() async {
      isar = await openTempIsar([NameModelSchema]);
    });

    isarTest('json', () async {
      await isar.tWriteTxn(
        () => isar.nameModels.tPut(
          NameModel()
            ..value = 'test'
            ..otherValue = 'test2',
        ),
      );

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
