import 'package:isar/isar.dart';
import 'package:test/test.dart';

import 'util/common.dart';
import 'user_model.dart';
import 'util/sync_async_helper.dart';

void main() {
  testSyncAsync(tests);
}

void tests() {
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
      await isar.writeTxn(() async {
        await col.putAll(users);
      });
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('0 offset', () async {
      final result = col.where().offset(0).tFindAll();
      await qEqual(result, users);
    });

    isarTest('big offset', () async {
      final result = col.where().offset(99).tFindAll();
      await qEqual(result, []);
    });

    isarTest('offset', () async {
      final result = col.where().offset(2).tFindAll();
      await qEqual(result, users.sublist(2, 5));
    });

    isarTest('0 limit', () async {
      final result = col.where().limit(0).tFindAll();
      await qEqual(result, []);
    });

    isarTest('big limit', () async {
      final result = col.where().limit(999999).tFindAll();
      await qEqual(result, users);
    });

    isarTest('limit', () async {
      final result = col.where().limit(3).tFindAll();
      await qEqual(result, users.sublist(0, 3));
    });

    isarTest('offset and limit', () async {
      final result = col.where().offset(3).limit(1).tFindAll();
      await qEqual(result, users.sublist(3, 4));
    });

    isarTest('offset and big limit', () async {
      final result = col.where().offset(3).limit(1000).tFindAll();
      await qEqual(result, users.sublist(3));
    });

    isarTest('big offset and big limit', () async {
      final result = col.where().offset(300).limit(5).tFindAll();
      await qEqual(result, []);
    });
  });
}
