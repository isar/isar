import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'put_by_test.g.dart';

@collection
class BoolIndexModel {
  BoolIndexModel({
    required this.value,
    required this.index,
  });

  Id id = Isar.autoIncrement;

  @Index(unique: true)
  final bool value;

  final int index;

  @override
  String toString() {
    return 'BoolIndexModel{id: $id, value: $value, index: $index}';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoolIndexModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          value == other.value &&
          index == other.index;
}

@collection
class IntIndexModel {
  IntIndexModel({
    required this.value,
    required this.index,
  });

  Id id = Isar.autoIncrement;

  @Index(unique: true)
  final int value;

  final int index;

  @override
  String toString() {
    return 'IntIndexModel{id: $id, value: $value, index: $index}';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntIndexModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          value == other.value &&
          index == other.index;
}

@collection
class DoubleIndexModel {
  DoubleIndexModel({
    required this.value,
    required this.index,
  });

  Id id = Isar.autoIncrement;

  @Index(unique: true)
  final double value;

  final int index;

  @override
  String toString() {
    return 'DoubleIndexModel{id: $id, value: $value, index: $index}';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoubleIndexModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          value == other.value &&
          index == other.index;
}

@collection
class StringValueIndexModel {
  StringValueIndexModel({
    required this.value,
    required this.index,
  });

  Id id = Isar.autoIncrement;

  @Index(unique: true, type: IndexType.value)
  final String value;

  final int index;

  @override
  String toString() {
    return 'StringValueIndexModel{id: $id, value: $value, index: $index}';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StringValueIndexModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          value == other.value &&
          index == other.index;
}

@collection
class StringHashIndexModel {
  StringHashIndexModel({
    required this.value,
    required this.index,
  });

  Id id = Isar.autoIncrement;

  @Index(unique: true, type: IndexType.hash)
  final String value;

  final int index;

  @override
  String toString() {
    return 'StringHashIndexModel{id: $id, value: $value, index: $index}';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StringHashIndexModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          value == other.value &&
          index == other.index;
}

@collection
class StringInsensitiveIndexModel {
  StringInsensitiveIndexModel({
    required this.value,
    required this.index,
  });

  Id id = Isar.autoIncrement;

  @Index(unique: true, caseSensitive: false)
  final String value;

  final int index;

  @override
  String toString() {
    return 'StringInsensitiveIndexModel{id: $id, value: $value, index: $index}';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StringInsensitiveIndexModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          value == other.value &&
          index == other.index;
}

void main() {
  group('Put by index', () {
    late Isar isar;

    setUp(() async {
      isar = await openTempIsar([
        BoolIndexModelSchema,
        IntIndexModelSchema,
        DoubleIndexModelSchema,
        StringValueIndexModelSchema,
        StringHashIndexModelSchema,
        StringInsensitiveIndexModelSchema,
      ]);
    });

    isarTest('Put by bool index', () async {
      final obj0 = BoolIndexModel(value: true, index: 0);
      final obj1 = BoolIndexModel(value: false, index: 1);
      final obj2 = BoolIndexModel(value: true, index: 2);

      await isar.tWriteTxn(() async {
        await isar.boolIndexModels.tPutAllByValue([obj0, obj1]);
        await isar.boolIndexModels.tPutByValue(obj2);
      });

      await qEqual(isar.boolIndexModels.where(), [obj2, obj1]);
      expect(obj0.id, obj2.id);

      await isar.tWriteTxn(() => isar.boolIndexModels.tPutByValue(obj0));
      await qEqual(isar.boolIndexModels.where(), [obj0, obj1]);
      expect(obj0.id, obj2.id);
    });

    isarTest('Put by int index', () async {
      final obj0 = IntIndexModel(value: 42, index: 0);
      final obj1 = IntIndexModel(value: 20, index: 1);
      final obj2 = IntIndexModel(value: 42, index: 2);
      final obj3 = IntIndexModel(value: 3, index: 3);

      await isar.tWriteTxn(
        () => isar.intIndexModels.tPutAllByValue([obj0, obj1, obj3]),
      );
      await qEqual(isar.intIndexModels.where(), [obj0, obj1, obj3]);

      await isar.tWriteTxn(() => isar.intIndexModels.tPutByValue(obj2));
      await qEqual(isar.intIndexModels.where(), [obj2, obj1, obj3]);
      expect(obj0.id, obj2.id);
    });

    isarTest('Put by double index', () async {
      final obj0 = DoubleIndexModel(value: 15.23, index: 0);
      final obj1 = DoubleIndexModel(value: 15.23, index: 1);
      final obj2 = DoubleIndexModel(value: 15.23, index: 2);
      final obj3 = DoubleIndexModel(value: 0, index: 3);

      await isar.tWriteTxn(
        () => isar.doubleIndexModels.tPutAllByValue([obj0, obj1, obj2, obj3]),
      );

      await qEqual(isar.doubleIndexModels.where(), [obj2, obj3]);
      expect(obj0.id, obj1.id);
      expect(obj0.id, obj2.id);
    });

    isarTest('Put by string value index', () async {
      final obj0 = StringValueIndexModel(value: 'Foo bar', index: 0);
      final obj1 = StringValueIndexModel(value: 'foo Bar', index: 1);
      final obj2 = StringValueIndexModel(value: 'Foo bar', index: 2);
      final obj3 = StringValueIndexModel(value: 'John Doe', index: 3);

      await isar.tWriteTxn(
        () => isar.stringValueIndexModels.tPutAllByValue([obj0, obj1]),
      );
      await qEqual(isar.stringValueIndexModels.where(), [obj0, obj1]);

      await isar.tWriteTxn(
        () => isar.stringValueIndexModels.tPutAllByValue([obj2, obj3]),
      );
      await qEqual(isar.stringValueIndexModels.where(), [obj2, obj1, obj3]);
      expect(obj0.id, obj2.id);

      await isar.tWriteTxn(() => isar.stringValueIndexModels.tPutByValue(obj0));
      await qEqual(isar.stringValueIndexModels.where(), [obj0, obj1, obj3]);
      expect(obj0.id, obj2.id);
    });

    isarTest('Put by string hash index', () async {
      final obj0 = StringHashIndexModel(value: 'abc', index: 0);
      final obj1 = StringHashIndexModel(value: 'xyz', index: 1);
      final obj2 = StringHashIndexModel(value: '123', index: 2);
      final obj3 = StringHashIndexModel(value: 'xyz', index: 3);
      final obj4 = StringHashIndexModel(value: 'abc', index: 4);

      await isar.tWriteTxn(
        () => isar.stringHashIndexModels.tPutAllByValue([obj0, obj1, obj2]),
      );
      await qEqual(isar.stringHashIndexModels.where(), [obj0, obj1, obj2]);

      await isar.tWriteTxn(
        () => isar.stringHashIndexModels.tPutAllByValue([obj3, obj4]),
      );
      await qEqual(isar.stringHashIndexModels.where(), [obj4, obj3, obj2]);
      expect(obj0.id, obj4.id);
      expect(obj1.id, obj3.id);

      await isar.tWriteTxn(
        () => isar.stringHashIndexModels.tPutByValue(obj0),
      );
      await qEqual(isar.stringHashIndexModels.where(), [obj0, obj3, obj2]);
      expect(obj0.id, obj4.id);
    });

    isarTest('Put by string insensitive index', () async {
      final obj0 = StringInsensitiveIndexModel(value: 'foo', index: 0);
      final obj1 = StringInsensitiveIndexModel(value: 'BAR', index: 1);
      final obj2 = StringInsensitiveIndexModel(value: 'Foo', index: 2);
      final obj3 = StringInsensitiveIndexModel(value: 'abc', index: 3);
      final obj4 = StringInsensitiveIndexModel(value: 'FoO', index: 4);
      final obj5 = StringInsensitiveIndexModel(value: 'Bar', index: 5);

      await isar.tWriteTxn(
        () => isar.stringInsensitiveIndexModels
            .tPutAllByValue([obj0, obj1, obj3]),
      );
      await qEqual(
        isar.stringInsensitiveIndexModels.where(),
        [obj0, obj1, obj3],
      );

      await isar.tWriteTxn(
        () => isar.stringInsensitiveIndexModels
            .tPutAllByValue([obj0, obj3, obj5]),
      );
      await qEqual(
        isar.stringInsensitiveIndexModels.where(),
        [obj0, obj5, obj3],
      );

      await isar.tWriteTxn(
        () => isar.stringInsensitiveIndexModels
            .tPutAllByValue([obj2, obj4, obj5]),
      );
      await qEqual(
        isar.stringInsensitiveIndexModels.where(),
        [obj4, obj5, obj3],
      );

      await isar.tWriteTxn(
        () => isar.stringInsensitiveIndexModels.tPutByValue(obj1),
      );
      await qEqual(
        isar.stringInsensitiveIndexModels.where(),
        [obj4, obj1, obj3],
      );
    });

    isarTest('Put all by without items', () async {
      final obj0 = BoolIndexModel(value: true, index: 0);
      final obj1 = BoolIndexModel(value: true, index: 1);

      await isar.tWriteTxn(() => isar.boolIndexModels.tPutAllByValue([]));
      await qEqual(isar.boolIndexModels.where(), []);

      await isar.tWriteTxn(() => isar.boolIndexModels.tPut(obj0));
      await qEqual(isar.boolIndexModels.where(), [obj0]);

      await isar.tWriteTxn(() => isar.boolIndexModels.tPutAllByValue([]));
      await isar.tWriteTxn(() => isar.boolIndexModels.tPutAllByValue([obj1]));
      await isar.tWriteTxn(() => isar.boolIndexModels.tPutAllByValue([]));

      await qEqual(isar.boolIndexModels.where(), [obj1]);
    });
  });
}

// Extension methods for collections, in order to use
// `tPutByValue` / `tPutAllByValue` on them
extension TBoolIndexModelCollectionExt on IsarCollection<BoolIndexModel> {
  Future<int> tPutByValue(BoolIndexModel obj) {
    if (syncTest) {
      return SynchronousFuture(putByValueSync(obj));
    }
    return putByValue(obj);
  }

  Future<List<int>> tPutAllByValue(List<BoolIndexModel> objs) {
    if (syncTest) {
      return SynchronousFuture(putAllByValueSync(objs));
    }
    return putAllByValue(objs);
  }
}

extension TIntIndexModelCollectionExt on IsarCollection<IntIndexModel> {
  Future<int> tPutByValue(IntIndexModel obj) {
    if (syncTest) {
      return SynchronousFuture(putByValueSync(obj));
    }
    return putByValue(obj);
  }

  Future<List<int>> tPutAllByValue(List<IntIndexModel> objs) {
    if (syncTest) {
      return SynchronousFuture(putAllByValueSync(objs));
    }
    return putAllByValue(objs);
  }
}

extension TDoubleIndexModelCollectionExt on IsarCollection<DoubleIndexModel> {
  Future<int> tPutByValue(DoubleIndexModel obj) {
    if (syncTest) {
      return SynchronousFuture(putByValueSync(obj));
    }
    return putByValue(obj);
  }

  Future<List<int>> tPutAllByValue(List<DoubleIndexModel> objs) {
    if (syncTest) {
      return SynchronousFuture(putAllByValueSync(objs));
    }
    return putAllByValue(objs);
  }
}

extension TStringValueIndexModelCollectionExt
    on IsarCollection<StringValueIndexModel> {
  Future<int> tPutByValue(StringValueIndexModel obj) {
    if (syncTest) {
      return SynchronousFuture(putByValueSync(obj));
    }
    return putByValue(obj);
  }

  Future<List<int>> tPutAllByValue(List<StringValueIndexModel> objs) {
    if (syncTest) {
      return SynchronousFuture(putAllByValueSync(objs));
    }
    return putAllByValue(objs);
  }
}

extension TStringHashIndexModelCollectionExt
    on IsarCollection<StringHashIndexModel> {
  Future<int> tPutByValue(StringHashIndexModel obj) {
    if (syncTest) {
      return SynchronousFuture(putByValueSync(obj));
    }
    return putByValue(obj);
  }

  Future<List<int>> tPutAllByValue(List<StringHashIndexModel> objs) {
    if (syncTest) {
      return SynchronousFuture(putAllByValueSync(objs));
    }
    return putAllByValue(objs);
  }
}

extension TStringInsensitiveIndexModelCollectionExt
    on IsarCollection<StringInsensitiveIndexModel> {
  Future<int> tPutByValue(StringInsensitiveIndexModel obj) {
    if (syncTest) {
      return SynchronousFuture(putByValueSync(obj));
    }
    return putByValue(obj);
  }

  Future<List<int>> tPutAllByValue(List<StringInsensitiveIndexModel> objs) {
    if (syncTest) {
      return SynchronousFuture(putAllByValueSync(objs));
    }
    return putAllByValue(objs);
  }
}
