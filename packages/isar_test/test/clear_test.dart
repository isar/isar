import 'dart:ffi';

import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'clear_test.g.dart';

@collection
class ModelA {
  ModelA(this.id, this.test, this.test2, this.test3,
      {required this.d, this.d2 = 0, this.d3 = 0, this.d4 = 0});

  @Id()
  int id;

  final String test;

  final String test2;

  final String test3;

  final double d;

  final int d2;

  final int d3;

  final int d4;

  //List<String>? hello;

  @override
  String toString() {
    // TODO: implement toString
    return '{$id $test $test2}';
  }
}

void main() {
  group('Clear', () {
    test('Test', () {
      final l = List.generate(
        1000,
        (index) => ModelA(
          index,
          'test$index',
          'test$index' * 10,
          'test$index',
          d: 1.0,
        ),
      );
      final ids = l.map((e) => e.id).toList();

      final isar = openTempIsar([ModelASchema]);

      final s1 = Stopwatch()..start();
      isar.writeTxn((isar) {
        for (var i = 0; i < 10; i++) {
          isar.collection<int, ModelA>().putAll(l);
        }
      });
      print(s1.elapsedMicroseconds);
      //print(serWatch.elapsedMicroseconds);

      final s = Stopwatch()..start();
      isar.txn((isar) {
        for (var i = 0; i < 1000; i++) {
          isar.collection<int, ModelA>().getAll(ids);
        }
      });
      print(s.elapsedMicroseconds);
      print(deserS.elapsedMicroseconds);
      print(deserS2.elapsedMicroseconds);

      //print(isar.modelAs.where().idGreaterThan(1).findAll(limit: 4));

      //print(deserWatch.elapsedMicroseconds);
    });
  });
}
