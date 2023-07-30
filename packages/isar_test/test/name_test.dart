import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'name_test.g.dart';

@collection
@Name('NameModelN')
class NameModel {
  NameModel(this.id);

  @Name('idN')
  int id;

  @Index()
  @Name('valueN')
  String? value;

  //@Index(composite: [CompositeIndex('value')])
  @Name('otherValueN')
  String? otherValue;
}

void main() {
  group('Name', () {
    late Isar isar;

    setUp(() async {
      isar = await openTempIsar([NameModelSchema]);
    });

    isarTest('json', () {
      isar.write(
        (isar) => isar.nameModels.put(
          NameModel(1)
            ..value = 'test'
            ..otherValue = 'test2',
        ),
      );

      expect(isar.nameModels.where().exportJson(), [
        {
          'idN': 1,
          'valueN': 'test',
          'otherValueN': 'test2',
        },
      ]);
    });
  });
}
