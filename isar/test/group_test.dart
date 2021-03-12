import 'package:isar/isar.dart';
import 'package:test/test.dart';

import 'common.dart';
import 'isar.g.dart';
import 'models/user_model.dart';

void main() {
  group('Groups', () {
    late Isar isar;
    late IsarCollection<UserModel> users;

    setUp(() async {
      setupIsar();

      final dir = await getTempDir();
      isar = await openIsar(directory: dir.path);
      users = isar.userModels;

      await isar.writeTxn((isar) async {
        await users.putAll([
          UserModel.fill('David', 20, false),
          UserModel.fill('Emma', 30, true),
          UserModel.fill('Tina', 40, false),
          UserModel.fill('Simon', 30, false),
          UserModel.fill('Bjorn', 40, true),
        ]);
      });
    });

    test('Simple or', () async {
      await qEqualSet(
        users.where().filter().ageEqualTo(20).or().ageEqualTo(30).findAll(),
        [
          UserModel.fill('David', 20, false),
          UserModel.fill('Emma', 30, true),
          UserModel.fill('Simon', 30, false),
        ],
      );

      await qEqualSet(
        users.where().filter().ageEqualTo(20).ageEqualTo(30).findAll(),
        [
          UserModel.fill('David', 20, false),
          UserModel.fill('Emma', 30, true),
          UserModel.fill('Simon', 30, false),
        ],
      );
    });

    test('Simple and', () async {
      await qEqualSet(
        users
            .where()
            .filter()
            .ageEqualTo(40)
            .and()
            .adminEqualTo(true)
            .findAll(),
        [UserModel.fill('Bjorn', 40, true)],
      );
    });

    test('Or followed by and', () async {
      await qEqualSet(
        users
            .where()
            .filter()
            .ageEqualTo(20)
            .or()
            .ageEqualTo(30)
            .and()
            .nameEqualTo('Emma')
            .findAll(),
        [
          UserModel.fill('David', 20, false),
          UserModel.fill('Emma', 30, true),
        ],
      );
    });

    test('And followed by or', () async {
      await qEqualSet(
        users
            .where()
            .filter()
            .ageEqualTo(30)
            .and()
            .nameEqualTo('Simon')
            .or()
            .ageEqualTo(20)
            .findAll(),
        [
          UserModel.fill('David', 20, false),
          UserModel.fill('Simon', 30, false),
        ],
      );
    });

    test('Or followed by group', () async {
      await qEqualSet(
        users
            .where()
            .filter()
            .ageEqualTo(20)
            .or()
            .group((q) => q.ageEqualTo(30).and().nameEqualTo('Emma'))
            .findAll(),
        [
          UserModel.fill('David', 20, false),
          UserModel.fill('Emma', 30, true),
        ],
      );
    });

    test('And followed by group', () async {
      await qEqualSet(
        users
            .where()
            .filter()
            .ageEqualTo(30)
            .and()
            .group((q) => q.nameEqualTo('Simon').or().ageEqualTo(20))
            .findAll(),
        [UserModel.fill('Simon', 30, false)],
      );
    });

    test('Nested groups', () async {
      await qEqualSet(
        users
            .where()
            .filter()
            .group(
              (q) => q
                  .nameEqualTo('Simon')
                  .or()
                  .group((q) => q.ageEqualTo(30).or().ageEqualTo(20)),
            )
            .findAll(),
        [
          UserModel.fill('Simon', 30, false),
          UserModel.fill('David', 20, false),
          UserModel.fill('Emma', 30, true),
        ],
      );
    });
  });
}
