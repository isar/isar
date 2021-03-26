import 'package:isar/isar.dart';
import 'package:isar_test/common.dart';
import 'package:isar_test/isar_test_context.dart';
import 'package:isar_test/models/user_model.dart';
import 'package:test/test.dart';

import 'isar.g.dart';

void run(IsarTestContext context) {
  group('OffsetLimit', () {
    late Isar isar;
    late IsarCollection<UserModel> col;
    late List<UserModel> users;

    setUp(() async {
      isar = await context.openIsar();
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

    context.test('0 offset', () async {
      final result = col.where().offset(0).findAll();
      await qEqual(result, users);
    });

    context.test('big offset', () async {
      final result = col.where().offset(99).findAll();
      await qEqual(result, []);
    });

    context.test('offset', () async {
      final result = col.where().offset(2).findAll();
      await qEqual(result, users.sublist(2, 5));
    });

    context.test('0 limit', () async {
      final result = col.where().limit(0).findAll();
      await qEqual(result, []);
    });

    context.test('big limit', () async {
      final result = col.where().limit(999999).findAll();
      await qEqual(result, users);
    });

    context.test('limit', () async {
      final result = col.where().limit(3).findAll();
      await qEqual(result, users.sublist(0, 3));
    });

    context.test('offset and limit', () async {
      final result = col.where().offset(3).limit(1).findAll();
      await qEqual(result, users.sublist(3, 4));
    });

    context.test('offset and big limit', () async {
      final result = col.where().offset(3).limit(1000).findAll();
      await qEqual(result, users.sublist(3));
    });

    context.test('big offset and big limit', () async {
      final result = col.where().offset(300).limit(5).findAll();
      await qEqual(result, []);
    });
  });
}
