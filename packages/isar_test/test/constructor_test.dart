import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:isar/isar.dart';
import 'package:test/test.dart';

import 'util/common.dart';
import 'util/sync_async_helper.dart';

part 'constructor_test.g.dart';
part 'constructor_test.freezed.dart';

@Collection()
class EmptyConstructorModel {
  EmptyConstructorModel();
  int? id;

  late String name;

  @override
  // ignore: hash_and_equals, always_declare_return_types
  operator ==(dynamic other) {
    return other is EmptyConstructorModel &&
        other.id == id &&
        other.name == name;
  }
}

@Collection()
class NamedConstructorModel {
  NamedConstructorModel({required this.name});
  int? id;

  final String name;

  @override
  // ignore: hash_and_equals, always_declare_return_types
  operator ==(dynamic other) {
    return other is NamedConstructorModel &&
        other.id == id &&
        other.name == name;
  }
}

@Collection()
class PositionalConstructorModel {
  PositionalConstructorModel(this.id, this.name);
  final int? id;

  final String name;

  @override
  // ignore: hash_and_equals, always_declare_return_types
  operator ==(dynamic other) {
    return other is PositionalConstructorModel &&
        other.id == id &&
        other.name == name;
  }
}

@Collection()
class OptionalConstructorModel {
  OptionalConstructorModel(this.name, [this.id]);
  final int? id;

  final String name;

  @override
  String toString() => '{id: $id, name: $name}';

  @override
  // ignore: hash_and_equals, always_declare_return_types
  operator ==(dynamic other) {
    return other is OptionalConstructorModel &&
        other.id == id &&
        other.name == name;
  }
}

@Collection()
class PositionalNamedConstructorModel {
  PositionalNamedConstructorModel(this.name, {required this.id});
  final int id;

  String name;

  @override
  // ignore: hash_and_equals, always_declare_return_types
  operator ==(dynamic other) {
    return other is PositionalNamedConstructorModel &&
        other.id == id &&
        other.name == name;
  }
}

@Collection()
class SerializeOnlyModel {
  SerializeOnlyModel(this.id);
  final int? id;

  final String name = 'myName';

  String get someGetter => '$name$name';

  @override
  // ignore: hash_and_equals, always_declare_return_types
  operator ==(dynamic other) {
    return other is SerializeOnlyModel && other.id == id;
  }
}

@freezed
@Collection()
class FreezedModel with _$FreezedModel {
  const factory FreezedModel({int? id, required String name}) = MyFreezedModel;
}

void main() {
  testSyncAsync(tests);
}

void tests() {
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
        FreezedModelSchema,
      ]);
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('EmptyConstructorModel', () async {
      final EmptyConstructorModel obj1 = EmptyConstructorModel()..name = 'obj1';
      final EmptyConstructorModel obj2 = EmptyConstructorModel()..name = 'obj2';
      await isar.tWriteTxn(() async {
        await isar.emptyConstructorModels.tPutAll([obj1, obj2]);
      });

      await qEqual(
          isar.emptyConstructorModels.where().tFindAll(), [obj1, obj2]);
    });

    isarTest('NamedConstructorModel', () async {
      final NamedConstructorModel obj1 = NamedConstructorModel(name: 'obj1');
      final NamedConstructorModel obj2 = NamedConstructorModel(name: 'obj2');
      await isar.tWriteTxn(() async {
        await isar.namedConstructorModels.tPutAll([obj1, obj2]);
      });

      await qEqual(
          isar.namedConstructorModels.where().tFindAll(), [obj1, obj2]);
    });

    isarTest('PositionalConstructorModel', () async {
      final PositionalConstructorModel obj1 =
          PositionalConstructorModel(0, 'obj1');
      final PositionalConstructorModel obj2 =
          PositionalConstructorModel(5, 'obj2');
      final PositionalConstructorModel obj3 =
          PositionalConstructorModel(15, 'obj3');
      await isar.tWriteTxn(() async {
        await isar.positionalConstructorModels.tPutAll([obj1, obj2, obj3]);
      });

      await qEqual(
        isar.positionalConstructorModels.where().tFindAll(),
        [obj1, obj2, obj3],
      );
    });

    isarTest('OptionalConstructorModel', () async {
      final OptionalConstructorModel obj1 = OptionalConstructorModel('obj1');
      final OptionalConstructorModel obj1WithId =
          OptionalConstructorModel('obj1', 1);
      final OptionalConstructorModel obj2 = OptionalConstructorModel('obj2', 5);
      final OptionalConstructorModel obj3 =
          OptionalConstructorModel('obj3', 15);
      await isar.tWriteTxn(() async {
        await isar.optionalConstructorModels.tPutAll([obj1, obj2, obj3]);
      });

      await qEqual(
        isar.optionalConstructorModels.where().tFindAll(),
        [obj1WithId, obj2, obj3],
      );
    });

    isarTest('PositionalNamedConstructorModel', () async {
      final PositionalNamedConstructorModel obj1 =
          PositionalNamedConstructorModel('obj1', id: 1);
      final PositionalNamedConstructorModel obj2 =
          PositionalNamedConstructorModel('obj2', id: 2);
      await isar.tWriteTxn(() async {
        await isar.positionalNamedConstructorModels.tPutAll([obj1, obj2]);
      });

      await qEqual(
        isar.positionalNamedConstructorModels.where().tFindAll(),
        [obj1, obj2],
      );
    });

    isarTest('FreezedModel', () async {
      const FreezedModel obj1 = FreezedModel(id: 1, name: 'obj1');
      const FreezedModel obj2 = FreezedModel(id: 2, name: 'obj2');
      await isar.tWriteTxn(() async {
        await isar.freezedModels.tPutAll([obj1, obj2]);
      });

      await qEqual(
        isar.freezedModels.where().tFindAll(),
        [obj1, obj2],
      );
    });
  });
}
