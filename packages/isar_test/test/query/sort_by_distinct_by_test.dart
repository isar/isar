import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

import '../user_model.dart';

void main() {
  group('Sort By', () {
    late Isar isar;
    late IsarCollection<UserModel> users;

    setUp(() async {
      isar = await openTempIsar([UserModelSchema]);
      users = isar.userModels;

      await isar.writeTxn(
        () => users.putAll([
          UserModel.fill('a', 100, true),
          UserModel.fill('a', 200, true),
          UserModel.fill('c', 1, false),
          UserModel.fill('c', 2, true),
          UserModel.fill('b', 10, true),
          UserModel.fill('b', 20, false),
        ]),
      );
    });

    isarTest('.sortBy()', () async {
      await qEqual(
        users.where().sortByName().nameProperty(),
        ['a', 'a', 'b', 'b', 'c', 'c'],
      );

      await qEqual(
        users.where().sortByName().thenByNameDesc().nameProperty(),
        ['a', 'a', 'b', 'b', 'c', 'c'],
      );

      await qEqual(
        users.where().sortByAge().ageProperty(),
        [1, 2, 10, 20, 100, 200],
      );

      await qEqual(
        users.where().sortByAdmin().adminProperty(),
        [false, false, true, true, true, true],
      );
    });

    isarTest('.sortByDesc()', () async {
      await qEqual(
        users.where().sortByNameDesc().nameProperty(),
        ['c', 'c', 'b', 'b', 'a', 'a'],
      );

      await qEqual(
        users.where().sortByAgeDesc().ageProperty(),
        [200, 100, 20, 10, 2, 1],
      );

      await qEqual(
        users.where().sortByAdminDesc().adminProperty(),
        [true, true, true, true, false, false],
      );
    });

    isarTest('.sortBy().thenBy()', () async {
      await qEqual(
        users.where().sortByName().thenByAge(),
        [
          UserModel.fill('a', 100, true),
          UserModel.fill('a', 200, true),
          UserModel.fill('b', 10, true),
          UserModel.fill('b', 20, false),
          UserModel.fill('c', 1, false),
          UserModel.fill('c', 2, true),
        ],
      );

      await qEqual(
        users.where().sortByAge().thenByName(),
        [
          UserModel.fill('c', 1, false),
          UserModel.fill('c', 2, true),
          UserModel.fill('b', 10, true),
          UserModel.fill('b', 20, false),
          UserModel.fill('a', 100, true),
          UserModel.fill('a', 200, true),
        ],
      );

      await qEqual(
        users.where().sortByAdmin().thenByName().thenByAge(),
        [
          UserModel.fill('b', 20, false),
          UserModel.fill('c', 1, false),
          UserModel.fill('a', 100, true),
          UserModel.fill('a', 200, true),
          UserModel.fill('b', 10, true),
          UserModel.fill('c', 2, true),
        ],
      );
    });
  });
}
