import 'package:isar/isar.dart';
import 'package:test/test.dart';

import 'common.dart';
import 'user_model.dart';

part 'crud_test.g.dart';

@Collection()
class Message {
  int? id;

  @Index()
  String? message;

  @override
  String toString() {
    return '{id: $id, message: $message}';
  }

  @override
  bool operator ==(dynamic other) {
    if (other is Message) {
      return other.message == message;
    } else {
      return false;
    }
  }
}

void main() {
  group('CRUD', () {
    late Isar isar;
    late IsarCollection<Message> messages;
    late IsarCollection<UserModel> users;

    setUp(() async {
      isar = await openTempIsar([MessageSchema, UserModelSchema]);
      messages = isar.messages;
      users = isar.userModels;
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('get() / put() without id', () async {
      final message1 = Message()
        ..id = Isar.autoIncrement
        ..message = 'This is a new message';
      final message2 = Message()..message = 'This is another new message';

      await isar.writeTxn((isar) async {
        message1.id = await messages.put(message1);
        message2.id = await messages.put(message2);
      });

      expect(message1.id, 1);
      final newMessage1 = await messages.get(message1.id!);
      expect(message1, newMessage1);

      expect(message2.id, 2);
      final newMessage2 = await messages.get(message2.id!);
      expect(message2, newMessage2);
    });

    isarTest('get() / put() with id', () async {
      final message1 = Message()
        ..id = 5
        ..message = 'This is a new message';
      final message2 = Message()..message = 'This is another new message';

      await isar.writeTxn((isar) async {
        await messages.put(message1);
        await messages.put(message2);
      });

      final newMessage1 = await messages.get(message1.id!);
      expect(message1.id, 5);
      expect(newMessage1, message1);

      expect(message2.id, 6);
      final newMessage2 = await messages.get(message2.id!);
      expect(newMessage2, message2);

      final noMessage = await messages.get(7);
      expect(noMessage, null);
    });

    isarTestVm('getSync() / putSync() without id', () {
      final message = Message()..message = 'This is a new message';

      isar.writeTxnSync((isar) {
        message.id = messages.putSync(message);
      });

      final newMessage = messages.getSync(message.id!);
      expect(message, newMessage);
    });

    isarTestVm('getSync() / putSync() with id', () {
      final message = Message()
        ..id = 5
        ..message = 'This is a new message';

      isar.writeTxnSync((isar) {
        messages.putSync(message);
      });

      final newMessage = messages.getSync(message.id!);
      expect(message, newMessage);

      final noMessage = messages.getSync(6);
      expect(noMessage, null);
    });

    isarTest('getAll() / putAll()', () async {
      final message1 = Message()..message = 'Message one';
      final message2 = Message()
        ..message = 'Message two'
        ..id = 9;
      final message3 = Message()..message = 'Message three';

      late List<int> ids;
      await isar.writeTxn((isar) async {
        ids = await messages.putAll([message1, message2, message3]);
      });

      expect(ids, [1, 9, 10]);
      final newMessages = await messages.getAll(ids);
      expect(newMessages, [message1, message2, message3]);
    });

    isarTestVm('getAllSync() / putAllSync()', () {
      final message1 = Message()..message = 'Message one';
      final message2 = Message()
        ..message = 'Message two'
        ..id = 9;
      final message3 = Message()..message = 'Message three';

      late List<int> ids;
      isar.writeTxnSync((isar) {
        ids = messages.putAllSync([message1, message2, message3]);
      });

      expect(ids, [1, 9, 10]);
      final newMessages = messages.getAllSync(ids);
      expect(newMessages, [message1, message2, message3]);
    });

    isarTest('delete()', () async {
      final user = UserModel()
        ..name = 'Some User'
        ..age = 24;

      await isar.writeTxn((isar) async {
        user.id = await users.put(user);
      });

      await isar.writeTxn((isar) async {
        await users.delete(9999);
      });
      expect(await users.get(user.id!), user);

      await isar.writeTxn((isar) async {
        await users.delete(user.id!);
      });
      expect(await users.get(user.id!), null);
    });

    isarTestVm('deleteSync()', () async {
      final user = UserModel()
        ..name = 'Some User'
        ..age = 24;

      isar.writeTxnSync((isar) {
        user.id = users.putSync(user);
      });

      isar.writeTxnSync((isar) {
        users.deleteSync(9999);
      });
      expect(users.getSync(user.id!), user);

      isar.writeTxnSync((isar) {
        users.deleteSync(user.id!);
      });
      expect(users.getSync(user.id!), null);
    });
  });
}
