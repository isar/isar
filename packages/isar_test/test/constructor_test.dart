import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'constructor_test.g.dart';

@collection
class EmptyConstructorModel {
  EmptyConstructorModel();

  @id
  late String name;

  @override
  // ignore: hash_and_equals
  bool operator ==(dynamic other) {
    return other is EmptyConstructorModel && other.name == name;
  }
}

@collection
class NamedConstructorModel {
  NamedConstructorModel({required this.name});

  @id
  final String name;

  @override
  // ignore: hash_and_equals
  bool operator ==(dynamic other) {
    return other is NamedConstructorModel && other.name == name;
  }
}

@collection
class PositionalConstructorModel {
  PositionalConstructorModel(this.name);

  @id
  final String name;

  @override
  // ignore: hash_and_equals
  bool operator ==(dynamic other) {
    return other is PositionalConstructorModel && other.name == name;
  }
}

@collection
class OptionalConstructorModel {
  OptionalConstructorModel([this.name = 'default']);

  @id
  final String name;

  int? value2;

  @override
  // ignore: hash_and_equals
  bool operator ==(dynamic other) {
    return other is OptionalConstructorModel &&
        other.name == name &&
        other.value2 == value2;
  }
}

@collection
class PositionalNamedConstructorModel {
  PositionalNamedConstructorModel(this.name, {required this.value2});

  @id
  final String name;

  final String value2;

  @override
  // ignore: hash_and_equals
  bool operator ==(dynamic other) {
    return other is PositionalNamedConstructorModel &&
        other.name == name &&
        other.value2 == value2;
  }
}

void main() {
  group('Constructor', () {
    late Isar isar;

    setUp(() async {
      isar = await openTempIsar([
        EmptyConstructorModelSchema,
        NamedConstructorModelSchema,
        PositionalConstructorModelSchema,
        OptionalConstructorModelSchema,
        PositionalNamedConstructorModelSchema,
      ]);
    });

    isarTest('EmptyConstructorModel', () {
      final obj1 = EmptyConstructorModel()..name = 'obj1';
      final obj2 = EmptyConstructorModel()..name = 'obj2';
      isar.write((isar) {
        isar.emptyConstructorModels.putAll([obj1, obj2]);
      });

      expect(
        isar.emptyConstructorModels.where().findAll().toSet(),
        {obj1, obj2},
      );
    });

    isarTest('NamedConstructorModel', () {
      final obj1 = NamedConstructorModel(name: 'obj1');
      final obj2 = NamedConstructorModel(name: 'obj2');
      isar.write((isar) {
        isar.namedConstructorModels.putAll([obj1, obj2]);
      });

      expect(
        isar.namedConstructorModels.where().findAll().toSet(),
        {obj1, obj2},
      );
    });

    isarTest('PositionalConstructorModel', () {
      final obj1 = PositionalConstructorModel('obj1');
      final obj2 = PositionalConstructorModel('obj2');
      final obj3 = PositionalConstructorModel('obj3');
      isar.write((isar) {
        isar.positionalConstructorModels.putAll([obj1, obj2, obj3]);
      });

      expect(
        isar.positionalConstructorModels.where().findAll().toSet(),
        {obj1, obj2, obj3},
      );
    });

    isarTest('OptionalConstructorModel', () {
      final obj1 = OptionalConstructorModel()..value2 = 1;
      final obj2 = OptionalConstructorModel('obj2')..value2 = 2;
      final obj3 = OptionalConstructorModel()..value2 = 3;
      final obj4 = OptionalConstructorModel('obj4')..value2 = 4;
      isar.write((isar) {
        isar.optionalConstructorModels.putAll([obj1, obj2, obj3, obj4]);
      });

      expect(
        isar.optionalConstructorModels.where().findAll().toSet(),
        {obj2, obj3, obj4},
      );
    });

    isarTest('PositionalNamedConstructorModel', () {
      final obj1 = PositionalNamedConstructorModel('obj1', value2: 'value2');
      final obj2 = PositionalNamedConstructorModel('obj2', value2: 'value2_2');
      isar.write((isar) {
        isar.positionalNamedConstructorModels.putAll([obj1, obj2]);
      });

      expect(
        isar.positionalNamedConstructorModels.where().findAll().toSet(),
        {obj1, obj2},
      );
    });
  });
}
