import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

import 'user_model.dart';

part 'crud_test.g.dart';

@collection
class Message {
  Id? id;

  @Index()
  String? message;

  @override
  String toString() {
    return '{id: $id, message: $message}';
  }

  @override
  // ignore: hash_and_equals
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

    isarTest('get() / put() without id', () async {
      final message1 = Message()
        ..id = Isar.autoIncrement
        ..message = 'This is a new message';
      final message2 = Message()..message = 'This is another new message';

      await isar.tWriteTxn(() async {
        message1.id = await messages.tPut(message1);
        message2.id = await messages.tPut(message2);
      });

      expect(message1.id, 1);
      final newMessage1 = await messages.tGet(message1.id!);
      expect(message1, newMessage1);

      expect(message2.id, 2);
      final newMessage2 = await messages.tGet(message2.id!);
      expect(message2, newMessage2);
    });

    isarTest('get() / put() with id', () async {
      final message1 = Message()
        ..id = 5
        ..message = 'This is a new message';
      final message2 = Message()..message = 'This is another new message';

      await isar.tWriteTxn(() async {
        await messages.tPut(message1);
        await messages.tPut(message2);
      });

      final newMessage1 = await messages.tGet(message1.id!);
      expect(message1.id, 5);
      expect(newMessage1, message1);

      expect(message2.id, 6);
      final newMessage2 = await messages.tGet(message2.id!);
      expect(newMessage2, message2);

      final noMessage = await messages.tGet(7);
      expect(noMessage, null);
    });

    isarTest('getAll() / putAll()', () async {
      final message1 = Message()..message = 'Message one';
      final message2 = Message()
        ..message = 'Message two'
        ..id = 9;
      final message3 = Message()..message = 'Message three';

      late List<Id> ids;
      await isar.tWriteTxn(() async {
        ids = await messages.tPutAll([message1, message2, message3]);
      });

      expect(ids, [1, 9, 10]);
      final newMessages = await messages.tGetAll(ids);
      expect(newMessages, [message1, message2, message3]);
    });

    isarTest('delete()', () async {
      final user = UserModel()
        ..name = 'Some User'
        ..age = 24;

      await isar.tWriteTxn(() async {
        user.id = await users.tPut(user);
      });

      await isar.tWriteTxn(() async {
        await users.tDelete(9999);
      });
      expect(await users.tGet(user.id!), user);

      await isar.tWriteTxn(() async {
        await users.tDelete(user.id!);
      });
      expect(await users.tGet(user.id!), null);
    });
  });
}
