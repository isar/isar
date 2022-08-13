import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../user_model.dart';
import '../util/common.dart';
import '../util/sync_async_helper.dart';

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
        users.where().sortByName().nameProperty().tFindAll(),
        ['a', 'a', 'b', 'b', 'c', 'c'],
      );

      await qEqual(
        users.where().sortByName().thenByNameDesc().nameProperty().tFindAll(),
        ['a', 'a', 'b', 'b', 'c', 'c'],
      );

      await qEqual(
        users.where().sortByAge().ageProperty().tFindAll(),
        [1, 2, 10, 20, 100, 200],
      );

      await qEqual(
        users.where().sortByAdmin().adminProperty().tFindAll(),
        [false, false, true, true, true, true],
      );
    });

    isarTest('.sortByDesc()', () async {
      await qEqual(
        users.where().sortByNameDesc().nameProperty().tFindAll(),
        ['c', 'c', 'b', 'b', 'a', 'a'],
      );

      await qEqual(
        users.where().sortByAgeDesc().ageProperty().tFindAll(),
        [200, 100, 20, 10, 2, 1],
      );

      await qEqual(
        users.where().sortByAdminDesc().adminProperty().tFindAll(),
        [true, true, true, true, false, false],
      );
    });

    isarTest('.sortBy().thenBy()', () async {
      await qEqual(
        users.where().sortByName().thenByAge().tFindAll(),
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
        users.where().sortByAge().thenByName().tFindAll(),
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
        users.where().sortByAdmin().thenByName().thenByAge().tFindAll(),
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
