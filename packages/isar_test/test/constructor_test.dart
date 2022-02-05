import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:isar/isar.dart';
import 'package:isar_test/common.dart';
import 'package:test/test.dart';

part 'constructor_test.g.dart';
part 'constructor_test.freezed.dart';

@Collection()
class EmptyConstructorModel {
  int? id;

  late String name;

  EmptyConstructorModel();

  @override
  operator ==(dynamic other) {
    return other is EmptyConstructorModel &&
        other.id == id &&
        other.name == name;
  }
}

@Collection()
class NamedConstructorModel {
  int? id;

  final String name;

  NamedConstructorModel({required this.name});

  @override
  operator ==(dynamic other) {
    return other is NamedConstructorModel &&
        other.id == id &&
        other.name == name;
  }
}

@Collection()
class PositionalConstructorModel {
  final int? id;

  final String name;

  PositionalConstructorModel(this.id, this.name);

  @override
  operator ==(dynamic other) {
    return other is PositionalConstructorModel &&
        other.id == id &&
        other.name == name;
  }
}

@Collection()
class OptionalConstructorModel {
  final int? id;

  final String name;

  OptionalConstructorModel(this.name, [this.id]);

  @override
  operator ==(dynamic other) {
    return other is OptionalConstructorModel &&
        other.id == id &&
        other.name == name;
  }
}

@Collection()
class PositionalNamedConstructorModel {
  final int id;

  String name;

  PositionalNamedConstructorModel(this.name, {required this.id});

  @override
  operator ==(dynamic other) {
    return other is PositionalNamedConstructorModel &&
        other.id == id &&
        other.name == name;
  }
}

@Collection()
class SerializeOnlyModel {
  final int? id;

  final String name = 'myName';

  String get someGetter => '$name$name';

  SerializeOnlyModel(this.id);

  @override
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
      final obj1 = EmptyConstructorModel()..name = 'obj1';
      final obj2 = EmptyConstructorModel()..name = 'obj2';
      await isar.writeTxn((isar) async {
        await isar.emptyConstructorModels.putAll([obj1, obj2]);
      });

      await qEqual(isar.emptyConstructorModels.where().findAll(), [obj1, obj2]);
    });

    isarTest('NamedConstructorModel', () async {
      final obj1 = NamedConstructorModel(name: 'obj1');
      final obj2 = NamedConstructorModel(name: 'obj2');
      await isar.writeTxn((isar) async {
        await isar.namedConstructorModels.putAll([obj1, obj2]);
      });

      await qEqual(isar.namedConstructorModels.where().findAll(), [obj1, obj2]);
    });

    isarTest('PositionalConstructorModel', () async {
      final obj1 = PositionalConstructorModel(0, 'obj1');
      final obj2 = PositionalConstructorModel(5, 'obj2');
      final obj3 = PositionalConstructorModel(15, 'obj3');
      await isar.writeTxn((isar) async {
        await isar.positionalConstructorModels.putAll([obj1, obj2, obj3]);
      });

      await qEqual(
        isar.positionalConstructorModels.where().findAll(),
        [obj1, obj2, obj3],
      );
    });

    isarTest('OptionalConstructorModel', () async {
      final obj1 = OptionalConstructorModel('obj1');
      final obj1WithId = OptionalConstructorModel('obj1', Isar.minId);
      final obj2 = OptionalConstructorModel('obj2', 5);
      final obj3 = OptionalConstructorModel('obj3', 15);
      await isar.writeTxn((isar) async {
        await isar.optionalConstructorModels.putAll([obj1, obj2, obj3]);
      });

      await qEqual(
        isar.optionalConstructorModels.where().findAll(),
        [obj1WithId, obj2, obj3],
      );
    });

    isarTest('PositionalNamedConstructorModel', () async {
      final obj1 = PositionalNamedConstructorModel('obj1', id: 1);
      final obj2 = PositionalNamedConstructorModel('obj2', id: 2);
      await isar.writeTxn((isar) async {
        await isar.positionalNamedConstructorModels.putAll([obj1, obj2]);
      });

      await qEqual(
        isar.positionalNamedConstructorModels.where().findAll(),
        [obj1, obj2],
      );
    });

    isarTest('FreezedModel', () async {
      const obj1 = FreezedModel(id: 1, name: 'obj1');
      const obj2 = FreezedModel(id: 2, name: 'obj2');
      await isar.writeTxn((isar) async {
        await isar.freezedModels.putAll([obj1, obj2]);
      });

      await qEqual(
        isar.freezedModels.where().findAll(),
        [obj1, obj2],
      );
    });
  });
}
