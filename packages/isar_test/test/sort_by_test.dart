import 'package:isar/isar.dart';
import 'package:isar_test/utils/common.dart';
import 'package:isar_test/utils/open.dart';
import 'package:isar_test/user_model.dart';
import 'package:isar_test/isar.g.dart';
import 'package:test/test.dart';

void main() {
  group('Sort By', () {
    late Isar isar;
    late IsarCollection<UserModel> users;

    setUp(() async {
      isar = await openTempIsar();
      users = isar.userModels;

      await isar.writeTxn(
        (isar) => users.putAll([
          UserModel.fill('a', 100, true),
          UserModel.fill('a', 200, true),
          UserModel.fill('c', 1, false),
          UserModel.fill('c', 2, true),
          UserModel.fill('b', 10, true),
          UserModel.fill('b', 20, false),
        ]),
      );
    });

    tearDown(() async {
      await isar.close();
    });

    test('.sortBy()', () async {
      await qEqual(
        users.where().sortByName().nameProperty().findAll(),
        ['a', 'a', 'b', 'b', 'c', 'c'],
      );

      await qEqual(
        users.where().sortByName().thenByNameDesc().nameProperty().findAll(),
        ['a', 'a', 'b', 'b', 'c', 'c'],
      );

      await qEqual(
        users.where().sortByAge().ageProperty().findAll(),
        [1, 2, 10, 20, 100, 200],
      );

      await qEqual(
        users.where().sortByAdmin().adminProperty().findAll(),
        [false, false, true, true, true, true],
      );
    });

    test('.sortByDesc()', () async {
      await qEqual(
        users.where().sortByNameDesc().nameProperty().findAll(),
        ['c', 'c', 'b', 'b', 'a', 'a'],
      );

      await qEqual(
        users.where().sortByAgeDesc().ageProperty().findAll(),
        [200, 100, 20, 10, 2, 1],
      );

      await qEqual(
        users.where().sortByAdminDesc().adminProperty().findAll(),
        [true, true, true, true, false, false],
      );
    });

    test('.sortBy().thenBy()', () async {
      await qEqual(
        users.where().sortByName().thenByAge().findAll(),
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
        users.where().sortByAge().thenByName().findAll(),
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
        users.where().sortByAdmin().thenByName().thenByAge().findAll(),
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
