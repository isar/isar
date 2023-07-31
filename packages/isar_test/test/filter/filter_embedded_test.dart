// ignore_for_file: hash_and_equals

import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'filter_embedded_test.g.dart';

@collection
class Model {
  Model({
    required this.id,
    required this.embeddedA,
    required this.embeddedB,
  });

  int id;

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
    required this.name,
    this.embeddedB,
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
  const EmbeddedModelB({required this.name});

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
        id: 1,
        embeddedA: const EmbeddedModelA(
          name: 'embedded a1',
          embeddedB: EmbeddedModelB(name: 'embedded a1 b1'),
        ),
        embeddedB: const EmbeddedModelB(name: 'embedded b1'),
      );
      obj2 = Model(
        id: 2,
        embeddedA: const EmbeddedModelA(
          name: 'embedded a2',
          embeddedB: EmbeddedModelB(name: 'embedded a2 b2'),
        ),
        embeddedB: null,
      );
      obj3 = Model(
        id: 3,
        embeddedA: const EmbeddedModelA(
          name: 'embedded a3',
        ),
        embeddedB: const EmbeddedModelB(name: 'embedded b3'),
      );
      obj4 = Model(
        id: 4,
        embeddedA: const EmbeddedModelA(
          name: 'embedded a4',
          embeddedB: EmbeddedModelB(name: 'embedded a4 b4'),
        ),
        embeddedB: const EmbeddedModelB(name: 'embedded b4'),
      );
      obj5 = Model(
        id: 5,
        embeddedA: const EmbeddedModelA(
          name: 'embedded a5',
        ),
        embeddedB: const EmbeddedModelB(name: 'embedded b5'),
      );
      obj6 = Model(
        id: 6,
        embeddedA: const EmbeddedModelA(
          name: 'embedded a6',
          embeddedB: EmbeddedModelB(name: 'embedded a6 b6'),
        ),
        embeddedB: null,
      );

      isar.write(
        (isar) => isar.models.putAll([obj1, obj2, obj3, obj4, obj5, obj6]),
      );
    });

    isarTest('.embedded()', () {
      expect(
        isar.models
            .where()
            .embeddedA((q) => q.nameStartsWith('embedded'))
            .findAll(),
        [obj1, obj2, obj3, obj4, obj5, obj6],
      );
      expect(
        isar.models
            .where()
            .embeddedA((q) => q.nameEqualTo('embedded a1'))
            .findAll(),
        [obj1],
      );
      expect(
        isar.models
            .where()
            .embeddedA((q) => q.nameEqualTo('embedded a2'))
            .findAll(),
        [obj2],
      );
      expect(
        isar.models
            .where()
            .embeddedA((q) => q.nameEqualTo('embedded a3'))
            .findAll(),
        [obj3],
      );
      expect(
        isar.models
            .where()
            .embeddedA((q) => q.nameEqualTo('embedded a4'))
            .findAll(),
        [obj4],
      );
      expect(
        isar.models
            .where()
            .embeddedA((q) => q.nameEqualTo('embedded a5'))
            .findAll(),
        [obj5],
      );
      expect(
        isar.models
            .where()
            .embeddedA((q) => q.nameEqualTo('embedded a6'))
            .findAll(),
        [obj6],
      );
      expect(
        isar.models
            .where()
            .embeddedA((q) => q.nameEqualTo('non existing'))
            .findAll(),
        isEmpty,
      );
      expect(
        isar.models
            .where()
            .embeddedA((q) => q.nameEqualTo('embedded b1'))
            .findAll(),
        isEmpty,
      );

      expect(
        isar.models
            .where()
            .embeddedB((q) => q.nameStartsWith('embedded'))
            .findAll(),
        [obj1, obj3, obj4, obj5],
      );
      expect(
        isar.models
            .where()
            .embeddedB((q) => q.nameEqualTo('embedded b1'))
            .findAll(),
        [obj1],
      );
      expect(
        isar.models
            .where()
            .embeddedB((q) => q.nameEqualTo('embedded b2'))
            .findAll(),
        isEmpty,
      );
      expect(
        isar.models
            .where()
            .embeddedB((q) => q.nameEqualTo('embedded b3'))
            .findAll(),
        [obj3],
      );
      expect(
        isar.models
            .where()
            .embeddedB((q) => q.nameEqualTo('embedded b4'))
            .findAll(),
        [obj4],
      );
      expect(
        isar.models
            .where()
            .embeddedB((q) => q.nameEqualTo('embedded b5'))
            .findAll(),
        [obj5],
      );
      expect(
        isar.models
            .where()
            .embeddedB((q) => q.nameEqualTo('embedded b6'))
            .findAll(),
        isEmpty,
      );
      expect(
        isar.models
            .where()
            .embeddedB((q) => q.nameEqualTo('non existing'))
            .findAll(),
        isEmpty,
      );
      expect(
        isar.models
            .where()
            .embeddedB((q) => q.nameEqualTo('embedded a1'))
            .findAll(),
        isEmpty,
      );
    });

    isarTest('.embeddedIsNull()', () {
      expect(
        isar.models.where().embeddedBIsNull().findAll(),
        [obj2, obj6],
      );
    });

    isarTest('.embeddedIsNotNull()', () {
      expect(
        isar.models.where().embeddedBIsNotNull().findAll(),
        [obj1, obj3, obj4, obj5],
      );
    });

    isarTest('.embedded() then .embedded()', () {
      expect(
        isar.models
            .where()
            .embeddedA(
              (q) => q.embeddedB(
                (q) => q.nameStartsWith('embedded'),
              ),
            )
            .findAll(),
        [obj1, obj2, obj4, obj6],
      );
      expect(
        isar.models
            .where()
            .embeddedA(
              (q) => q.embeddedB(
                (q) => q.nameEqualTo('embedded a1 b1'),
              ),
            )
            .findAll(),
        [obj1],
      );
      expect(
        isar.models
            .where()
            .embeddedA(
              (q) => q.embeddedB(
                (q) => q.nameEqualTo('embedded a2 b2'),
              ),
            )
            .findAll(),
        [obj2],
      );
      expect(
        isar.models
            .where()
            .embeddedA(
              (q) => q.embeddedB(
                (q) => q.nameEqualTo('embedded a3 b3'),
              ),
            )
            .findAll(),
        isEmpty,
      );
      expect(
        isar.models
            .where()
            .embeddedA(
              (q) => q.embeddedB(
                (q) => q.nameEqualTo('embedded a4 b4'),
              ),
            )
            .findAll(),
        [obj4],
      );
      expect(
        isar.models
            .where()
            .embeddedA(
              (q) => q.embeddedB(
                (q) => q.nameEqualTo('embedded a5 b5'),
              ),
            )
            .findAll(),
        isEmpty,
      );
      expect(
        isar.models
            .where()
            .embeddedA(
              (q) => q.embeddedB(
                (q) => q.nameEqualTo('embedded a6 b6'),
              ),
            )
            .findAll(),
        [obj6],
      );
      expect(
        isar.models
            .where()
            .embeddedA(
              (q) => q.embeddedB(
                (q) => q.nameEqualTo('non existing'),
              ),
            )
            .findAll(),
        isEmpty,
      );
    });

    isarTest('.embedded() then .embeddedIsNull()', () {
      expect(
        isar.models.where().embeddedA((q) => q.embeddedBIsNull()).findAll(),
        [obj3, obj5],
      );
    });

    isarTest('.embedded() then .embeddedIsNotNull()', () {
      expect(
        isar.models.where().embeddedA((q) => q.embeddedBIsNotNull()).findAll(),
        [obj1, obj2, obj4, obj6],
      );
    });
  });
}
