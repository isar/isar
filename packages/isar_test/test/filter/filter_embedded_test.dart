// ignore_for_file: hash_and_equals

import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/matchers.dart';
import '../util/sync_async_helper.dart';

part 'filter_embedded_test.g.dart';

@collection
class Model {
  Model({
    required this.embeddedA,
    required this.embeddedB,
  });

  Id id = Isar.autoIncrement;

  // FIXME: Generator doesn't prevent us from indexing this field, but crashes
  // at runtime (...objects cannot be indexed)
  // @Index()
  EmbeddedModelA embeddedA;

  EmbeddedModelB? embeddedB;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Model &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          embeddedA == other.embeddedA &&
          embeddedB == other.embeddedB;

  @override
  String toString() {
    return '''Model{id: $id, embeddedA: $embeddedA, embeddedB: $embeddedB}''';
  }
}

@embedded
class EmbeddedModelA {
  const EmbeddedModelA({
    this.name = '',
    this.embeddedB = const EmbeddedModelB(),
  });

  final String name;

  final EmbeddedModelB? embeddedB;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmbeddedModelA &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          embeddedB == other.embeddedB;

  @override
  String toString() {
    return 'EmbeddedModelA{name: $name, embeddedB: $embeddedB}';
  }
}

@embedded
class EmbeddedModelB {
  const EmbeddedModelB({
    this.name = '',
  });

  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmbeddedModelB &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  String toString() {
    return 'EmbeddedModelB{name: $name}';
  }
}

void main() {
  group('Filter embedded', () {
    late Isar isar;

    late Model obj1;
    late Model obj2;
    late Model obj3;
    late Model obj4;
    late Model obj5;
    late Model obj6;

    setUp(() async {
      isar = await openTempIsar([ModelSchema]);

      obj1 = Model(
        embeddedA: const EmbeddedModelA(
          name: 'embedded a1',
          embeddedB: EmbeddedModelB(name: 'embedded a1 b1'),
        ),
        embeddedB: const EmbeddedModelB(name: 'embedded b1'),
      );
      obj2 = Model(
        embeddedA: const EmbeddedModelA(
          name: 'embedded a2',
          embeddedB: EmbeddedModelB(name: 'embedded a2 b2'),
        ),
        embeddedB: null,
      );
      obj3 = Model(
        embeddedA: const EmbeddedModelA(
          name: 'embedded a3',
          embeddedB: null,
        ),
        embeddedB: const EmbeddedModelB(name: 'embedded b3'),
      );
      obj4 = Model(
        embeddedA: const EmbeddedModelA(
          name: 'embedded a4',
          embeddedB: EmbeddedModelB(name: 'embedded a4 b4'),
        ),
        embeddedB: const EmbeddedModelB(name: 'embedded b4'),
      );
      obj5 = Model(
        embeddedA: const EmbeddedModelA(
          name: 'embedded a5',
          embeddedB: null,
        ),
        embeddedB: const EmbeddedModelB(name: 'embedded b5'),
      );
      obj6 = Model(
        embeddedA: const EmbeddedModelA(
          name: 'embedded a6',
          embeddedB: EmbeddedModelB(name: 'embedded a6 b6'),
        ),
        embeddedB: null,
      );

      await isar.tWriteTxn(
        () => isar.models.tPutAll([
          obj1,
          obj2,
          obj3,
          obj4,
          obj5,
          obj6,
        ]),
      );
    });

    // FIXME: IsarError: Unsupported type for condition
    isarTest('.equalTo()', () async {
      await qEqualSet(
        isar.models.filter().embeddedAEqualTo(obj1.embeddedA),
        [obj1],
      );
      await qEqualSet(
        isar.models.filter().embeddedAEqualTo(obj2.embeddedA),
        [obj2],
      );
      await qEqualSet(
        isar.models.filter().embeddedAEqualTo(obj3.embeddedA),
        [obj3],
      );
      await qEqualSet(
        isar.models.filter().embeddedAEqualTo(obj4.embeddedA),
        [obj4],
      );
      await qEqualSet(
        isar.models.filter().embeddedAEqualTo(obj5.embeddedA),
        [obj5],
      );
      await qEqualSet(
        isar.models.filter().embeddedAEqualTo(obj6.embeddedA),
        [obj6],
      );
      await qEqualSet(
        isar.models.filter().embeddedAEqualTo(
              const EmbeddedModelA(
                name: 'non existing',
              ),
            ),
        [],
      );

      await qEqualSet(
        isar.models.filter().embeddedBEqualTo(obj1.embeddedB),
        [obj1],
      );
      await qEqualSet(
        isar.models.filter().embeddedBEqualTo(obj3.embeddedB),
        [obj3],
      );
      await qEqualSet(
        isar.models.filter().embeddedBEqualTo(obj4.embeddedB),
        [obj4],
      );
      await qEqualSet(
        isar.models.filter().embeddedBEqualTo(obj5.embeddedB),
        [obj5],
      );
      await qEqualSet(
        isar.models.filter().embeddedBEqualTo(
              const EmbeddedModelB(
                name: 'non existing',
              ),
            ),
        [],
      );
    });

    isarTest('.embedded()', () async {
      await qEqualSet(
        isar.models.filter().embeddedA((q) => q.nameStartsWith('embedded')),
        [obj1, obj2, obj3, obj4, obj5, obj6],
      );
      await qEqualSet(
        isar.models.filter().embeddedA((q) => q.nameEqualTo('embedded a1')),
        [obj1],
      );
      await qEqualSet(
        isar.models.filter().embeddedA((q) => q.nameEqualTo('embedded a2')),
        [obj2],
      );
      await qEqualSet(
        isar.models.filter().embeddedA((q) => q.nameEqualTo('embedded a3')),
        [obj3],
      );
      await qEqualSet(
        isar.models.filter().embeddedA((q) => q.nameEqualTo('embedded a4')),
        [obj4],
      );
      await qEqualSet(
        isar.models.filter().embeddedA((q) => q.nameEqualTo('embedded a5')),
        [obj5],
      );
      await qEqualSet(
        isar.models.filter().embeddedA((q) => q.nameEqualTo('embedded a6')),
        [obj6],
      );
      await qEqualSet(
        isar.models.filter().embeddedA((q) => q.nameEqualTo('non existing')),
        [],
      );
      await qEqualSet(
        isar.models.filter().embeddedA((q) => q.nameEqualTo('embedded b1')),
        [],
      );

      await qEqualSet(
        isar.models.filter().embeddedB((q) => q.nameStartsWith('embedded')),
        [obj1, obj3, obj4, obj5],
      );
      await qEqualSet(
        isar.models.filter().embeddedB((q) => q.nameEqualTo('embedded b1')),
        [obj1],
      );
      await qEqualSet(
        isar.models.filter().embeddedB((q) => q.nameEqualTo('embedded b2')),
        [],
      );
      await qEqualSet(
        isar.models.filter().embeddedB((q) => q.nameEqualTo('embedded b3')),
        [obj3],
      );
      await qEqualSet(
        isar.models.filter().embeddedB((q) => q.nameEqualTo('embedded b4')),
        [obj4],
      );
      await qEqualSet(
        isar.models.filter().embeddedB((q) => q.nameEqualTo('embedded b5')),
        [obj5],
      );
      await qEqualSet(
        isar.models.filter().embeddedB((q) => q.nameEqualTo('embedded b6')),
        [],
      );
      await qEqualSet(
        isar.models.filter().embeddedB((q) => q.nameEqualTo('non existing')),
        [],
      );
      await qEqualSet(
        isar.models.filter().embeddedB((q) => q.nameEqualTo('embedded a1')),
        [],
      );
    });

    isarTest('.embeddedIsNull()', () async {
      await qEqualSet(
        isar.models.filter().embeddedBIsNull(),
        [obj2, obj6],
      );
    });

    isarTest('.embeddedIsNotNull()', () async {
      await qEqualSet(
        isar.models.filter().embeddedBIsNotNull(),
        [obj1, obj3, obj4, obj5],
      );
    });

    // FIXME: IsarError: Unsupported type for condition
    isarTest('.embedded() then .embeddedEqualTo()', () async {
      await qEqualSet(
        isar.models
            .filter()
            .embeddedA((q) => q.embeddedBEqualTo(obj1.embeddedA.embeddedB)),
        [obj1],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedA((q) => q.embeddedBEqualTo(obj2.embeddedA.embeddedB)),
        [obj2],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedA((q) => q.embeddedBEqualTo(obj3.embeddedA.embeddedB)),
        [obj3, obj5],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedA((q) => q.embeddedBEqualTo(obj4.embeddedA.embeddedB)),
        [obj4],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedA((q) => q.embeddedBEqualTo(obj5.embeddedA.embeddedB)),
        [obj3, obj5],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedA((q) => q.embeddedBEqualTo(obj6.embeddedA.embeddedB)),
        [obj6],
      );
    });

    // FIXME(severe): panic
    // Shell: thread 'isarworker' panicked at 'range start index 6579554 out of
    // range for slice of length 11', library/core/src/slice/index.rs:52:5
    isarTest('.embedded() then .embedded()', () async {
      await qEqualSet(
        isar.models.filter().embeddedA(
              (q) => q.embeddedB(
                (q) => q.nameStartsWith('embedded'),
              ),
            ),
        [obj1, obj2, obj4, obj6],
      );
      await qEqualSet(
        isar.models.filter().embeddedA(
              (q) => q.embeddedB(
                (q) => q.nameEqualTo('embedded a1 b1'),
              ),
            ),
        [obj1],
      );
      await qEqualSet(
        isar.models.filter().embeddedA(
              (q) => q.embeddedB(
                (q) => q.nameEqualTo('embedded a2 b2'),
              ),
            ),
        [obj2],
      );
      await qEqualSet(
        isar.models.filter().embeddedA(
              (q) => q.embeddedB(
                (q) => q.nameEqualTo('embedded a3 b3'),
              ),
            ),
        [],
      );
      await qEqualSet(
        isar.models.filter().embeddedA(
              (q) => q.embeddedB(
                (q) => q.nameEqualTo('embedded a4 b4'),
              ),
            ),
        [obj4],
      );
      await qEqualSet(
        isar.models.filter().embeddedA(
              (q) => q.embeddedB(
                (q) => q.nameEqualTo('embedded a5 b5'),
              ),
            ),
        [],
      );
      await qEqualSet(
        isar.models.filter().embeddedA(
              (q) => q.embeddedB(
                (q) => q.nameEqualTo('embedded a6 b6'),
              ),
            ),
        [obj6],
      );
      await qEqualSet(
        isar.models.filter().embeddedA(
              (q) => q.embeddedB(
                (q) => q.nameEqualTo('non existing'),
              ),
            ),
        [],
      );
    });

    isarTest('.embedded() then .embeddedIsNull()', () async {
      await qEqualSet(
        isar.models.filter().embeddedA((q) => q.embeddedBIsNull()),
        [obj3, obj5],
      );
    });

    isarTest('.embedded() then .embeddedIsNotNull()', () async {
      await qEqualSet(
        isar.models.filter().embeddedA((q) => q.embeddedBIsNotNull()),
        [obj1, obj2, obj4, obj6],
      );
    });
  });
}
