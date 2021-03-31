import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:isar_test/common.dart';
import 'package:isar_test/isar_test_context.dart';
import 'package:isar_test/models/message_model.dart';
import 'package:test/test.dart';

import 'isar.g.dart';
import 'models/link_model.dart';

void run(IsarTestContext context) {
  final encoder = Utf8Encoder();

  group('JSON', () {
    late Isar isar;
    late IsarCollection<Message> messages;
    final firstMessage = Message()..message = 'first';

    setUp(() async {
      isar = await context.openIsar();
      messages = isar.messages;
      await isar.writeTxn((isar) => messages.put(firstMessage));
    });

    tearDown(() async {
      await isar.close();
    });

    context.test('Import empty', () async {
      final json = encoder.convert(jsonEncode([]));

      await isar.writeTxn((isar) => messages.importJson(json));

      await qEqual(messages.where().findAll(), [firstMessage]);
    });

    context.test('Import without id', () async {
      final json = encoder.convert(jsonEncode([
        {'message': 'hello'}
      ]));
      await isar.writeTxn((isar) => messages.importJson(json));

      /*qEqual(messages.where().findAll(), [
        firstMessage,
        Message()..message = 'hello',
      ]);*/
    });

    context.test('Import with id', () async {
      final json = encoder.convert(jsonEncode([
        {'id': 25, 'message': 'hello'}
      ]));
      await isar.writeTxn((isar) => messages.importJson(json));

      final results = await messages.where().findAll();
      expect(results[1].id, 25);
    });

    context.test('Import malformed', () async {
      final json = encoder.convert(jsonEncode([
        {'messagee': 'hello'}
      ]));
      expect(() async {
        await isar.writeTxn((isar) => messages.importJson(json));
      }, throwsA(anything));
    });
  });
}
