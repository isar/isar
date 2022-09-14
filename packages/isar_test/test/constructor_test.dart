import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'constructor_test.g.dart';

@collection
class EmptyConstructorModel {
  EmptyConstructorModel();
  Id? id;

  late String name;

  @override
  // ignore: hash_and_equals
  bool operator ==(dynamic other) {
    return other is EmptyConstructorModel &&
        other.id == id &&
        other.name == name;
  }
}

@collection
class NamedConstructorModel {
  NamedConstructorModel({required this.name});
  Id? id;

  final String name;

  @override
  // ignore: hash_and_equals
  bool operator ==(dynamic other) {
    return other is NamedConstructorModel &&
        other.id == id &&
        other.name == name;
  }
}

@collection
class PositionalConstructorModel {
  PositionalConstructorModel(this.id, this.name);
  final Id? id;

  final String name;

  @override
  // ignore: hash_and_equals
  bool operator ==(dynamic other) {
    return other is PositionalConstructorModel &&
        other.id == id &&
        other.name == name;
  }
}

@collection
class OptionalConstructorModel {
  OptionalConstructorModel(this.name, [this.id]);
  final Id? id;

  final String name;

  @override
  String toString() => '{id: $id, name: $name}';

  @override
  // ignore: hash_and_equals
  bool operator ==(dynamic other) {
    return other is OptionalConstructorModel &&
        other.id == id &&
        other.name == name;
  }
}

@collection
class PositionalNamedConstructorModel {
  PositionalNamedConstructorModel(this.name, {required this.id});
  final Id id;

  String name;

  @override
  // ignore: hash_and_equals
  bool operator ==(dynamic other) {
    return other is PositionalNamedConstructorModel &&
        other.id == id &&
        other.name == name;
  }
}

@collection
class SerializeOnlyModel {
  SerializeOnlyModel(this.id);
  final Id? id;

  final String name = 'myName';

  String get someGetter => '$name$name';

  @override
  // ignore: hash_and_equals
  bool operator ==(dynamic other) {
    return other is SerializeOnlyModel && other.id == id;
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
        SerializeOnlyModelSchema,
      ]);
    });

    isarTest('EmptyConstructorModel', () async {
      final obj1 = EmptyConstructorModel()..name = 'obj1';
      final obj2 = EmptyConstructorModel()..name = 'obj2';
      await isar.tWriteTxn(() async {
        await isar.emptyConstructorModels.tPutAll([obj1, obj2]);
      });

      await qEqual(
        isar.emptyConstructorModels.where(),
        [obj1, obj2],
      );
    });

    isarTest('NamedConstructorModel', () async {
      final obj1 = NamedConstructorModel(name: 'obj1');
      final obj2 = NamedConstructorModel(name: 'obj2');
      await isar.tWriteTxn(() async {
        await isar.namedConstructorModels.tPutAll([obj1, obj2]);
      });

      await qEqual(
        isar.namedConstructorModels.where(),
        [obj1, obj2],
      );
    });

    isarTest('PositionalConstructorModel', () async {
      final obj1 = PositionalConstructorModel(0, 'obj1');
      final obj2 = PositionalConstructorModel(5, 'obj2');
      final obj3 = PositionalConstructorModel(15, 'obj3');
      await isar.tWriteTxn(() async {
        await isar.positionalConstructorModels.tPutAll([obj1, obj2, obj3]);
      });

      await qEqual(
        isar.positionalConstructorModels.where(),
        [obj1, obj2, obj3],
      );
    });

    isarTest('OptionalConstructorModel', () async {
      final obj1 = OptionalConstructorModel('obj1');
      final obj1WithId = OptionalConstructorModel('obj1', 1);
      final obj2 = OptionalConstructorModel('obj2', 5);
      final obj3 = OptionalConstructorModel('obj3', 15);
      await isar.tWriteTxn(() async {
        await isar.optionalConstructorModels.tPutAll([obj1, obj2, obj3]);
      });

      await qEqual(
        isar.optionalConstructorModels.where(),
        [obj1WithId, obj2, obj3],
      );
    });

    isarTest('PositionalNamedConstructorModel', () async {
      final obj1 = PositionalNamedConstructorModel('obj1', id: 1);
      final obj2 = PositionalNamedConstructorModel('obj2', id: 2);
      await isar.tWriteTxn(() async {
        await isar.positionalNamedConstructorModels.tPutAll([obj1, obj2]);
      });

      await qEqual(
        isar.positionalNamedConstructorModels.where(),
        [obj1, obj2],
      );
    });
  });
}
