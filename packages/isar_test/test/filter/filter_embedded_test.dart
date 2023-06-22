// ignore_for_file: hash_and_equals

/*import 'dart:math';

import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'filter_embedded_test.g.dart';

@collection
class Model {
  Model({
    required this.embeddedA,
    required this.embeddedB,
  });

  int id = Random().nextInt(99999);

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

    setUp(() {
      isar = openTempIsar([ModelSchema]);

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

      isar.tWriteTxn(
        () => isar.models.putAll([obj1, obj2, obj3, obj4, obj5, obj6]),
      );
    });

    isarTest('.embedded()', () {
      qEqualSet(
        isar.models.where().embeddedA((q) => q.nameStartsWith('embedded')),
        [obj1, obj2, obj3, obj4, obj5, obj6],
      );
      qEqualSet(
        isar.models.where().embeddedA((q) => q.nameEqualTo('embedded a1')),
        [obj1],
      );
      qEqualSet(
        isar.models.where().embeddedA((q) => q.nameEqualTo('embedded a2')),
        [obj2],
      );
      qEqualSet(
        isar.models.where().embeddedA((q) => q.nameEqualTo('embedded a3')),
        [obj3],
      );
      qEqualSet(
        isar.models.where().embeddedA((q) => q.nameEqualTo('embedded a4')),
        [obj4],
      );
      qEqualSet(
        isar.models.where().embeddedA((q) => q.nameEqualTo('embedded a5')),
        [obj5],
      );
      qEqualSet(
        isar.models.where().embeddedA((q) => q.nameEqualTo('embedded a6')),
        [obj6],
      );
      qEqualSet(
        isar.models.where().embeddedA((q) => q.nameEqualTo('non existing')),
        [],
      );
      qEqualSet(
        isar.models.where().embeddedA((q) => q.nameEqualTo('embedded b1')),
        [],
      );

      qEqualSet(
        isar.models.where().embeddedB((q) => q.nameStartsWith('embedded')),
        [obj1, obj3, obj4, obj5],
      );
      qEqualSet(
        isar.models.where().embeddedB((q) => q.nameEqualTo('embedded b1')),
        [obj1],
      );
      qEqualSet(
        isar.models.where().embeddedB((q) => q.nameEqualTo('embedded b2')),
        [],
      );
      qEqualSet(
        isar.models.where().embeddedB((q) => q.nameEqualTo('embedded b3')),
        [obj3],
      );
      qEqualSet(
        isar.models.where().embeddedB((q) => q.nameEqualTo('embedded b4')),
        [obj4],
      );
      qEqualSet(
        isar.models.where().embeddedB((q) => q.nameEqualTo('embedded b5')),
        [obj5],
      );
      qEqualSet(
        isar.models.where().embeddedB((q) => q.nameEqualTo('embedded b6')),
        [],
      );
      qEqualSet(
        isar.models.where().embeddedB((q) => q.nameEqualTo('non existing')),
        [],
      );
      qEqualSet(
        isar.models.where().embeddedB((q) => q.nameEqualTo('embedded a1')),
        [],
      );
    });

    isarTest('.embeddedIsNull()', () {
      qEqualSet(
        isar.models.where().embeddedBIsNull(),
        [obj2, obj6],
      );
    });

    isarTest('.embeddedIsNotNull()', () {
      qEqualSet(
        isar.models.where().embeddedBIsNotNull(),
        [obj1, obj3, obj4, obj5],
      );
    });

    isarTest('.embedded() then .embedded()', () {
      qEqualSet(
        isar.models.where().embeddedA(
              (q) => q.embeddedB(
                (q) => q.nameStartsWith('embedded'),
              ),
            ),
        [obj1, obj2, obj4, obj6],
      );
      qEqualSet(
        isar.models.where().embeddedA(
              (q) => q.embeddedB(
                (q) => q.nameEqualTo('embedded a1 b1'),
              ),
            ),
        [obj1],
      );
      qEqualSet(
        isar.models.where().embeddedA(
              (q) => q.embeddedB(
                (q) => q.nameEqualTo('embedded a2 b2'),
              ),
            ),
        [obj2],
      );
      qEqualSet(
        isar.models.where().embeddedA(
              (q) => q.embeddedB(
                (q) => q.nameEqualTo('embedded a3 b3'),
              ),
            ),
        [],
      );
      qEqualSet(
        isar.models.where().embeddedA(
              (q) => q.embeddedB(
                (q) => q.nameEqualTo('embedded a4 b4'),
              ),
            ),
        [obj4],
      );
      qEqualSet(
        isar.models.where().embeddedA(
              (q) => q.embeddedB(
                (q) => q.nameEqualTo('embedded a5 b5'),
              ),
            ),
        [],
      );
      qEqualSet(
        isar.models.where().embeddedA(
              (q) => q.embeddedB(
                (q) => q.nameEqualTo('embedded a6 b6'),
              ),
            ),
        [obj6],
      );
      qEqualSet(
        isar.models.where().embeddedA(
              (q) => q.embeddedB(
                (q) => q.nameEqualTo('non existing'),
              ),
            ),
        [],
      );
    });

    isarTest('.embedded() then .embeddedIsNull()', () {
      qEqualSet(
        isar.models.where().embeddedA((q) => q.embeddedBIsNull()),
        [obj3, obj5],
      );
    });

    isarTest('.embedded() then .embeddedIsNotNull()', () {
      qEqualSet(
        isar.models.where().embeddedA((q) => q.embeddedBIsNotNull()),
        [obj1, obj2, obj4, obj6],
      );
    });
  });
}
*/