import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'dynamic_test.g.dart';

@collection
class Model {
  Model({
    required this.id,
    required this.value,
    required this.list,
    required this.map,
  });

  final int id;

  final dynamic value;

  final List<dynamic> list;

  final Map<String, dynamic> map;

  @override
  bool operator ==(other) =>
      other is Model &&
      id == other.id &&
      listEquals([value], [other.value]) &&
      listEquals(list, other.list) &&
      listEquals(map.keys.toList(), other.map.keys.toList()) &&
      listEquals(map.values.toList(), other.map.values.toList());
}

void main() {
  group('Dynamic', () {
    late Isar isar;

    setUp(() async {
      isar = await openTempIsar([ModelSchema]);
    });

    isarTest('String', () {
      final obj1 = Model(
        id: 1,
        value: 'a',
        list: ['a', null, 'value'],
        map: {'a': 'hello'},
      );

      isar.write((isar) => isar.models.put(obj1));
      expect(isar.models.get(1), obj1);
    });

    isarTest('int', () {
      final obj1 = Model(
        id: 1,
        value: 1,
        list: [1, null, 2],
        map: {'a': 1},
      );

      isar.write((isar) => isar.models.put(obj1));
      expect(isar.models.get(1), obj1);
    });

    isarTest('double', () {
      final obj1 = Model(
        id: 1,
        value: 1.1,
        list: [1.1, null, 2.2],
        map: {'a': 1.1},
      );

      isar.write((isar) => isar.models.put(obj1));
      expect(isar.models.get(1), obj1);
    });

    isarTest('bool', () {
      final obj1 = Model(
        id: 1,
        value: true,
        list: [true, null, false],
        map: {'a': true},
      );

      isar.write((isar) => isar.models.put(obj1));
      expect(isar.models.get(1), obj1);
    });

    isarTest('null', () {
      final obj1 = Model(
        id: 1,
        value: null,
        list: [null, null, null],
        map: {'a': null},
      );

      isar.write((isar) => isar.models.put(obj1));
      expect(isar.models.get(1), obj1);
    });

    isarTest('List', () {
      final obj1 = Model(
        id: 1,
        value: [8, 'aaa', false, null],
        list: [
          [1, 'a', true, null],
          null,
          [2, 'b', true, null],
        ],
        map: {
          'a': [1, 'a', true, null],
        },
      );

      isar.write((isar) => isar.models.put(obj1));
      expect(isar.models.get(1), obj1);
    });

    isarTest('Map', () {
      final obj1 = Model(
        id: 1,
        value: {'a': 1, 'b': '2', 'c': true, 'd': null},
        list: [
          {'a': 1, 'b': '2', 'c': true, 'd': null},
          null,
          {'a': 2, 'b': '3', 'c': true, 'd': null},
        ],
        map: {
          'a': {'a': 1, 'b': '2', 'c': true, 'd': null},
        },
      );

      isar.write((isar) => isar.models.put(obj1));
      expect(isar.models.get(1), obj1);
    });
  });
}
