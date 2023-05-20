import 'dart:async';

import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

import 'user_model.dart';

void main() {
  group('open / close isar listener', () {
    isarTest('Open listener', () async {
      final streamController = StreamController<Isar>();
      void openListener(Isar isar) => streamController.add(isar);
      Isar.addOpenListener(openListener);
      final listener = Listener(streamController.stream);

      final isar1 = await openTempIsar([UserModelSchema]);
      final listenedIsar1 = await listener.next;
      expect(isar1, listenedIsar1);
      await isar1.close(deleteFromDisk: true);

      final isar2 = await openTempIsar([UserModelSchema]);
      final listenerIsar2 = await listener.next;
      expect(isar2, listenerIsar2);
      await isar2.close(deleteFromDisk: true);

      Isar.removeOpenListener(openListener);
      await listener.done();
      await streamController.close();
    });

    isarTest('Close listener', () async {
      final streamController = StreamController<String>();
      void closeListener(String name) => streamController.add(name);
      Isar.addCloseListener(closeListener);
      final listener = Listener(streamController.stream);

      final isar1 = await openTempIsar([UserModelSchema]);
      await isar1.close(deleteFromDisk: true);
      final listenedName1 = await listener.next;
      expect(isar1.name, listenedName1);

      final isar2 = await openTempIsar([UserModelSchema]);
      await isar2.close(deleteFromDisk: true);
      final listenedName2 = await listener.next;
      expect(isar2.name, listenedName2);

      Isar.removeCloseListener(closeListener);
      await listener.done();
      await streamController.close();
    });
  });
}
