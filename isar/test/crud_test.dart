import 'package:isar/isar.dart';
import 'package:test/test.dart';

import 'common.dart';
import 'isar.g.dart';
import 'models/user_model.dart';

void main() {
  group('CRUD', () {
    late Isar isar;
    late IsarCollection<String, UserModel> users;

    setUp(() async {
      setupIsar();

      final dir = await getTempDir();
      isar = await openIsar(directory: dir.path);
      users = isar.userModels;
    });

    /*test('get() / put() without oid', () async {
      final user = UserModel()
        ..name = 'Some User'
        ..age = 24;

      await isar.writeTxn((isar) async {
        await col.put(user);
      });

      final newUser = await col.get(user.id!);
      expect(user, newUser);
      expect(user.id, newUser!.id);
    });*/

    test('get() / put() with oid', () async {
      final user = UserModel()
        ..name = 'Some User'
        ..age = 24
        ..friends = ['Friend1', null, 'Friend2'];

      await isar.writeTxn((isar) async {
        await users.put(user);
      });

      final newUser = await users.get(user.name);
      expect(newUser, user);

      user.age = 25;
      await isar.writeTxn((isar) async {
        await users.put(user);
      });
      final newUser2 = await users.get(user.name);
      expect(newUser2, user);
    });

    test('get() / put() null', () async {
      final user = await users.get('Nonexisting User');
      expect(user, null);
    });

    test('delete()', () async {
      final user = UserModel()
        ..name = 'Some User'
        ..age = 24;

      await isar.writeTxn((isar) async {
        await users.put(user);
      });

      await isar.writeTxn((isar) async {
        await users.delete('Nonexisting User');
      });
      expect(await users.get(user.name), user);

      await isar.writeTxn((isar) async {
        await users.delete(user.name);
      });
      expect(await users.get(user.name), null);
    });

    test('putAll()', () async {
      final user1 = UserModel()
        ..name = 'Some User'
        ..age = 24
        ..friends = ['Friend'];

      final user2 = UserModel()
        ..name = 'Some other user'
        ..age = 24;

      await isar.writeTxn((isar) async {
        await users.putAll([user1, user2]);
      });

      final newUser1 = await users.get(user1.name);
      expect(newUser1, user1);

      final newUser2 = await users.get(user2.name);
      expect(newUser2, user2);
    });
  });
}
