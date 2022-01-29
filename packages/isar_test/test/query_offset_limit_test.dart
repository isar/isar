import 'package:isar/isar.dart';
import 'common.dart';

import 'package:isar_test/user_model.dart';
import 'package:test/test.dart';

void main() {
  group('OffsetLimit', () {
    late Isar isar;
    late IsarCollection<UserModel> col;
    late List<UserModel> users;

    setUp(() async {
      isar = await openTempIsar([UserModelSchema]);
      col = isar.userModels;

      users = [
        UserModel.fill('user1', 10, false),
        UserModel.fill('user2', 20, false),
        UserModel.fill('user3', 30, true),
        UserModel.fill('user4', 40, false),
        UserModel.fill('user5', 50, false),
      ];
      await isar.writeTxn((isar) async {
        await col.putAll(users);
      });
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('0 offset', () async {
      final result = col.where().offset(0).findAll();
      await qEqual(result, users);
    });

    isarTest('big offset', () async {
      final result = col.where().offset(99).findAll();
      await qEqual(result, []);
    });

    isarTest('offset', () async {
      final result = col.where().offset(2).findAll();
      await qEqual(result, users.sublist(2, 5));
    });

    isarTest('0 limit', () async {
      final result = col.where().limit(0).findAll();
      await qEqual(result, []);
    });

    isarTest('big limit', () async {
      final result = col.where().limit(999999).findAll();
      await qEqual(result, users);
    });

    isarTest('limit', () async {
      final result = col.where().limit(3).findAll();
      await qEqual(result, users.sublist(0, 3));
    });

    isarTest('offset and limit', () async {
      final result = col.where().offset(3).limit(1).findAll();
      await qEqual(result, users.sublist(3, 4));
    });

    isarTest('offset and big limit', () async {
      final result = col.where().offset(3).limit(1000).findAll();
      await qEqual(result, users.sublist(3));
    });

    isarTest('big offset and big limit', () async {
      final result = col.where().offset(300).limit(5).findAll();
      await qEqual(result, []);
    });
  });
}
