// ignore_for_file: hash_and_equals

/*import 'dart:math';

import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'filter_embedded_list_test.g.dart';

@collection
class Model {
  Model({
    required this.embeddedAs,
    required this.embeddedBs,
  });

  int id = Random().nextInt(99999);

  List<EmbeddedA> embeddedAs;

  List<EmbeddedB?>? embeddedBs;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Model &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          listEquals(embeddedAs, other.embeddedAs) &&
          listEquals(embeddedBs, other.embeddedBs);

  @override
  String toString() {
    return 'Model{id: $id, embeddedAs: $embeddedAs, embeddedBs: $embeddedBs}';
  }
}

@embedded
class EmbeddedA {
  EmbeddedA({
    this.name = '',
    this.embeddedBs = const [],
  });

  String name;

  final List<EmbeddedB?>? embeddedBs;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmbeddedA &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          listEquals(embeddedBs, other.embeddedBs);

  @override
  String toString() {
    return 'EmbeddedA{name: $name, embeddedBs: $embeddedBs}';
  }
}

@embedded
class EmbeddedB {
  EmbeddedB({
    this.name = '',
  });

  String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmbeddedB &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  String toString() {
    return 'EmbeddedB{name: $name}';
  }
}

void main() {
  group('Filter embedded list', () {
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
        embeddedAs: [
          EmbeddedA(
            name: 'embedded a1 - 1',
            embeddedBs: null,
          ),
          EmbeddedA(
            name: 'embedded a1 - 2',
            embeddedBs: [null, null],
          ),
          EmbeddedA(
            name: 'embedded a1 - 3',
            embeddedBs: [
              EmbeddedB(
                name: 'embedded a1 b1 - 1',
              ),
              EmbeddedB(
                name: 'embedded a1 b1 - 2',
              ),
              EmbeddedB(
                name: 'embedded a1 b1 - 3',
              ),
            ],
          ),
        ],
        embeddedBs: [
          EmbeddedB(name: 'embedded b1 - 1'),
          EmbeddedB(name: 'embedded b1 - 2'),
          EmbeddedB(name: 'embedded b1 - 3'),
        ],
      );
      obj2 = Model(
        embeddedAs: [
          EmbeddedA(
            name: 'embedded a2 - 1',
            embeddedBs: null,
          ),
        ],
        embeddedBs: [null],
      );
      obj3 = Model(
        embeddedAs: [
          EmbeddedA(
            name: 'embedded a3 - 1',
            embeddedBs: [
              null,
              EmbeddedB(name: 'embedded a3 b3 - 1'),
            ],
          ),
        ],
        embeddedBs: null,
      );
      obj4 = Model(
        embeddedAs: [],
        embeddedBs: [],
      );
      obj5 = Model(
        embeddedAs: [
          EmbeddedA(
            name: 'embedded a5 - 1',
            embeddedBs: [
              EmbeddedB(name: 'embedded a5 b5 - 1'),
              EmbeddedB(name: 'embedded a5 b5 - 2'),
              EmbeddedB(name: 'embedded a5 b5 - 3'),
              EmbeddedB(name: 'embedded a5 b5 - 4'),
              EmbeddedB(name: 'embedded a5 b5 - 5'),
            ],
          ),
        ],
        embeddedBs: [
          EmbeddedB(name: 'embedded b5 - 1'),
          EmbeddedB(name: 'embedded b5 - 2'),
          EmbeddedB(name: 'embedded b5 - 3'),
          EmbeddedB(name: 'embedded b5 - 4'),
          EmbeddedB(name: 'embedded b5 - 5'),
        ],
      );
      obj6 = Model(
        embeddedAs: [
          EmbeddedA(
            name: 'embedded a6 - 1',
            embeddedBs: [
              EmbeddedB(name: 'embedded a6 b6 - 1'),
              null,
              null,
              null,
            ],
          ),
        ],
        embeddedBs: [
          null,
          EmbeddedB(name: 'embedded b6 - 1'),
          null,
        ],
      );

      isar.tWriteTxn(
        () => isar.models.tPutAll([obj1, obj2, obj3, obj4, obj5, obj6]),
      );
    });

    isarTest('.embeddedIsNull()', () {
      expect(
        isar.models.where().embeddedBsIsNull(),
        [obj3],
      );
    });

    isarTest('.embeddedIsNotNull()', () {
      expect(
        isar.models.where().embeddedBsIsNotNull(),
        [obj1, obj2, obj4, obj5, obj6],
      );
    });

    isarTest('.embeddedLengthEqualTo()', () {
      expect(
        isar.models.where().embeddedAsLengthEqualTo(0),
        [obj4],
      );
      expect(
        isar.models.where().embeddedAsLengthEqualTo(1),
        [obj2, obj3, obj5, obj6],
      );
      expect(
        isar.models.where().embeddedAsLengthEqualTo(3),
        [obj1],
      );
      expect(
        isar.models.where().embeddedAsLengthEqualTo(4),
        [],
      );

      expect(
        isar.models.where().embeddedBsLengthEqualTo(0),
        [obj4],
      );
      expect(
        isar.models.where().embeddedBsLengthEqualTo(1),
        [obj2],
      );
      expect(
        isar.models.where().embeddedBsLengthEqualTo(2),
        [],
      );
      expect(
        isar.models.where().embeddedBsLengthEqualTo(3),
        [obj1, obj6],
      );
      expect(
        isar.models.where().embeddedBsLengthEqualTo(4),
        [],
      );
      expect(
        isar.models.where().embeddedBsLengthEqualTo(5),
        [obj5],
      );
      expect(
        isar.models.where().embeddedBsLengthEqualTo(6),
        [],
      );
    });

    isarTest('.embeddedLengthGreaterThan()', () {
      expect(
        isar.models.where().embeddedAsLengthGreaterThan(0),
        [obj1, obj2, obj3, obj5, obj6],
      );
      expect(
        isar.models.where().embeddedAsLengthGreaterThan(1),
        [obj1],
      );
      expect(
        isar.models.where().embeddedAsLengthGreaterThan(2),
        [obj1],
      );
      expect(
        isar.models.where().embeddedAsLengthGreaterThan(3, include: true),
        [obj1],
      );
      expect(
        isar.models.where().embeddedAsLengthGreaterThan(3),
        [],
      );

      expect(
        isar.models.where().embeddedBsLengthGreaterThan(0),
        [obj1, obj2, obj5, obj6],
      );
      expect(
        isar.models.where().embeddedBsLengthGreaterThan(1),
        [obj1, obj5, obj6],
      );
      expect(
        isar.models.where().embeddedBsLengthGreaterThan(2),
        [obj1, obj5, obj6],
      );
      expect(
        isar.models.where().embeddedBsLengthGreaterThan(3),
        [obj5],
      );
      expect(
        isar.models.where().embeddedBsLengthGreaterThan(4),
        [obj5],
      );
      expect(
        isar.models.where().embeddedBsLengthGreaterThan(5, include: true),
        [obj5],
      );
      expect(
        isar.models.where().embeddedBsLengthGreaterThan(5),
        [],
      );
    });

    isarTest('.embeddedLengthLessThanThan()', () {
      expect(
        isar.models.where().embeddedAsLengthLessThan(0),
        [],
      );
      expect(
        isar.models.where().embeddedAsLengthLessThan(1),
        [obj4],
      );
      expect(
        isar.models.where().embeddedAsLengthLessThan(2),
        [obj2, obj3, obj4, obj5, obj6],
      );
      expect(
        isar.models.where().embeddedAsLengthLessThan(3),
        [obj2, obj3, obj4, obj5, obj6],
      );
      expect(
        isar.models.where().embeddedAsLengthLessThan(3),
        [obj2, obj3, obj4, obj5, obj6],
      );
      expect(
        isar.models.where().embeddedAsLengthLessThan(3, include: true),
        [obj1, obj2, obj3, obj4, obj5, obj6],
      );

      expect(
        isar.models.where().embeddedBsLengthLessThan(0),
        [],
      );
      expect(
        isar.models.where().embeddedBsLengthLessThan(1),
        [obj4],
      );
      expect(
        isar.models.where().embeddedBsLengthLessThan(2),
        [obj2, obj4],
      );
      expect(
        isar.models.where().embeddedBsLengthLessThan(3),
        [obj2, obj4],
      );
      expect(
        isar.models.where().embeddedBsLengthLessThan(4),
        [obj1, obj2, obj4, obj6],
      );
      expect(
        isar.models.where().embeddedBsLengthLessThan(5),
        [obj1, obj2, obj4, obj6],
      );
      expect(
        isar.models.where().embeddedBsLengthLessThan(5, include: true),
        [obj1, obj2, obj4, obj5, obj6],
      );
    });

    isarTest('.embeddedLengthBetweenThan()', () {
      expect(
        isar.models.where().embeddedAsLengthBetween(1, 3),
        [obj1, obj2, obj3, obj5, obj6],
      );
      expect(
        isar.models.where().embeddedAsLengthBetween(3, 4),
        [obj1],
      );
      expect(
        isar.models.where().embeddedAsLengthBetween(10, 12),
        [],
      );

      expect(
        isar.models.where().embeddedBsLengthBetween(1, 3),
        [obj1, obj2, obj6],
      );
      expect(
        isar.models.where().embeddedBsLengthBetween(3, 4),
        [obj1, obj6],
      );
      expect(
        isar.models.where().embeddedBsLengthBetween(10, 12),
        [],
      );
    });

    isarTest('.embeddedIsEmpty()', () {
      expect(
        isar.models.where().embeddedAsIsEmpty(),
        [obj4],
      );

      expect(
        isar.models.where().embeddedBsIsEmpty(),
        [obj4],
      );
    });

    isarTest('.embeddedIsNotEmpty()', () {
      expect(
        isar.models.where().embeddedAsIsNotEmpty(),
        [obj1, obj2, obj3, obj5, obj6],
      );

      expect(
        isar.models.where().embeddedBsIsNotEmpty(),
        [obj1, obj2, obj5, obj6],
      );
    });

    isarTest('.embeddedElementIsNull()', () {
      expect(
        isar.models.where().embeddedBsElementIsNull(),
        [obj2, obj6],
      );
    });

    isarTest('.embeddedElementIsNotNull()', () {
      expect(
        isar.models.where().embeddedBsElementIsNotNull(),
        [obj1, obj5, obj6],
      );
    });

    isarTest('.embeddedElement()', () {
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.nameStartsWith('embedded')),
        [obj1, obj2, obj3, obj5, obj6],
      );
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.nameEqualTo('embedded a1 - 1')),
        [obj1],
      );
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.nameEqualTo('embedded a1 - 2')),
        [obj1],
      );
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.nameEqualTo('embedded a1 - 3')),
        [obj1],
      );
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.nameEqualTo('embedded a2 - 1')),
        [obj2],
      );
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.nameEqualTo('embedded a3 - 1')),
        [obj3],
      );
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.nameEqualTo('embedded a5 - 1')),
        [obj5],
      );
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.nameEqualTo('embedded a6 - 1')),
        [obj6],
      );
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.nameEqualTo('non existing')),
        [],
      );

      expect(
        isar.models
            .where()
            .embeddedBsElement((q) => q.nameStartsWith('embedded')),
        [obj1, obj5, obj6],
      );
      expect(
        isar.models
            .where()
            .embeddedBsElement((q) => q.nameEqualTo('embedded b1 - 1')),
        [obj1],
      );
      expect(
        isar.models
            .where()
            .embeddedBsElement((q) => q.nameEqualTo('embedded b1 - 2')),
        [obj1],
      );
      expect(
        isar.models
            .where()
            .embeddedBsElement((q) => q.nameEqualTo('embedded b1 - 3')),
        [obj1],
      );
      expect(
        isar.models
            .where()
            .embeddedBsElement((q) => q.nameEqualTo('embedded b5 - 1')),
        [obj5],
      );
      expect(
        isar.models
            .where()
            .embeddedBsElement((q) => q.nameEqualTo('embedded b5 - 2')),
        [obj5],
      );
      expect(
        isar.models
            .where()
            .embeddedBsElement((q) => q.nameEqualTo('embedded b5 - 3')),
        [obj5],
      );
      expect(
        isar.models
            .where()
            .embeddedBsElement((q) => q.nameEqualTo('embedded b5 - 4')),
        [obj5],
      );
      expect(
        isar.models
            .where()
            .embeddedBsElement((q) => q.nameEqualTo('embedded b5 - 5')),
        [obj5],
      );
      expect(
        isar.models
            .where()
            .embeddedBsElement((q) => q.nameEqualTo('embedded b6 - 1')),
        [obj6],
      );
      expect(
        isar.models
            .where()
            .embeddedBsElement((q) => q.nameEqualTo('non existing')),
        [],
      );
    });

    isarTest('.embeddedElement() then .embeddedIsNull()', () {
      expect(
        isar.models.where().embeddedAsElement((q) => q.embeddedBsIsNull()),
        [obj1, obj2],
      );
    });

    isarTest('.embeddedElement() then .embeddedIsNotNull()', () {
      expect(
        isar.models.where().embeddedAsElement((q) => q.embeddedBsIsNotNull()),
        [obj1, obj3, obj5, obj6],
      );
    });

    isarTest('.embeddedElement() then .embeddedLengthEqualTo()', () {
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.embeddedBsLengthEqualTo(0)),
        [],
      );
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.embeddedBsLengthEqualTo(1)),
        [],
      );
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.embeddedBsLengthEqualTo(2)),
        [obj1, obj3],
      );
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.embeddedBsLengthEqualTo(3)),
        [obj1],
      );
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.embeddedBsLengthEqualTo(4)),
        [obj6],
      );
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.embeddedBsLengthEqualTo(5)),
        [obj5],
      );
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.embeddedBsLengthEqualTo(6)),
        [],
      );
    });

    isarTest('.embeddedElement() then .embeddedLengthLessThan()', () {
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.embeddedBsLengthLessThan(0)),
        [],
      );
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.embeddedBsLengthLessThan(1)),
        [],
      );
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.embeddedBsLengthLessThan(2)),
        [],
      );
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.embeddedBsLengthLessThan(3)),
        [obj1, obj3],
      );
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.embeddedBsLengthLessThan(4)),
        [obj1, obj3],
      );
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.embeddedBsLengthLessThan(5)),
        [obj1, obj3, obj6],
      );
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.embeddedBsLengthLessThan(6)),
        [obj1, obj3, obj5, obj6],
      );
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.embeddedBsLengthLessThan(7)),
        [obj1, obj3, obj5, obj6],
      );
    });

    isarTest('.embeddedElement() then .embeddedLengthGreaterThan()', () {
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.embeddedBsLengthGreaterThan(0)),
        [obj1, obj3, obj5, obj6],
      );
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.embeddedBsLengthGreaterThan(1)),
        [obj1, obj3, obj5, obj6],
      );
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.embeddedBsLengthGreaterThan(2)),
        [obj1, obj5, obj6],
      );
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.embeddedBsLengthGreaterThan(3)),
        [obj5, obj6],
      );
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.embeddedBsLengthGreaterThan(4)),
        [obj5],
      );
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.embeddedBsLengthGreaterThan(5)),
        [],
      );
    });

    isarTest('.embeddedElement() then .embeddedLengthBetween()', () {
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.embeddedBsLengthBetween(2, 4)),
        [obj1, obj3, obj6],
      );
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.embeddedBsLengthBetween(3, 4)),
        [obj1, obj6],
      );
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.embeddedBsLengthBetween(5, 42)),
        [obj5],
      );
    });

    isarTest('.embeddedElement() then .embeddedIsEmpty()', () {
      expect(
        isar.models.where().embeddedAsElement((q) => q.embeddedBsIsEmpty()),
        [],
      );
    });

    isarTest('.embeddedElement() then .embeddedIsNotEmpty()', () {
      expect(
        isar.models.where().embeddedAsElement((q) => q.embeddedBsIsNotEmpty()),
        [obj1, obj3, obj5, obj6],
      );
    });

    isarTest('.embeddedElement() then .embeddedElementIsNull()', () {
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.embeddedBsElementIsNull()),
        [obj1, obj3, obj6],
      );
    });

    isarTest('.embeddedElement() then .embeddedElementIsNotNull()', () {
      expect(
        isar.models
            .where()
            .embeddedAsElement((q) => q.embeddedBsElementIsNotNull()),
        [obj1, obj3, obj5, obj6],
      );
    });

    isarTest('.embeddedElement() then .embeddedElement()', () {
      expect(
        isar.models.where().embeddedAsElement(
              (q) => q.embeddedBsElement(
                (q) => q.nameStartsWith('embedded'),
              ),
            ),
        [obj1, obj3, obj5, obj6],
      );

      expect(
        isar.models.where().embeddedAsElement(
              (q) => q.embeddedBsElement(
                (q) => q.nameEqualTo('embedded a1 b1 - 1'),
              ),
            ),
        [obj1],
      );
      expect(
        isar.models.where().embeddedAsElement(
              (q) => q.embeddedBsElement(
                (q) => q.nameEqualTo('embedded a1 b1 - 2'),
              ),
            ),
        [obj1],
      );
      expect(
        isar.models.where().embeddedAsElement(
              (q) => q.embeddedBsElement(
                (q) => q.nameEqualTo('embedded a1 b1 - 3'),
              ),
            ),
        [obj1],
      );

      expect(
        isar.models.where().embeddedAsElement(
              (q) => q.embeddedBsElement(
                (q) => q.nameEqualTo('embedded a3 b3 - 1'),
              ),
            ),
        [obj3],
      );

      expect(
        isar.models.where().embeddedAsElement(
              (q) => q.embeddedBsElement(
                (q) => q.nameEqualTo('embedded a5 b5 - 1'),
              ),
            ),
        [obj5],
      );
      expect(
        isar.models.where().embeddedAsElement(
              (q) => q.embeddedBsElement(
                (q) => q.nameEqualTo('embedded a5 b5 - 2'),
              ),
            ),
        [obj5],
      );
      expect(
        isar.models.where().embeddedAsElement(
              (q) => q.embeddedBsElement(
                (q) => q.nameEqualTo('embedded a5 b5 - 3'),
              ),
            ),
        [obj5],
      );
      expect(
        isar.models.where().embeddedAsElement(
              (q) => q.embeddedBsElement(
                (q) => q.nameEqualTo('embedded a5 b5 - 4'),
              ),
            ),
        [obj5],
      );
      expect(
        isar.models.where().embeddedAsElement(
              (q) => q.embeddedBsElement(
                (q) => q.nameEqualTo('embedded a5 b5 - 5'),
              ),
            ),
        [obj5],
      );

      expect(
        isar.models.where().embeddedAsElement(
              (q) => q.embeddedBsElement(
                (q) => q.nameEqualTo('embedded a6 b6 - 1'),
              ),
            ),
        [obj6],
      );

      expect(
        isar.models.where().embeddedAsElement(
              (q) => q.embeddedBsElement(
                (q) => q.nameEqualTo('non existing'),
              ),
            ),
        [],
      );
    });
  });
}*/
