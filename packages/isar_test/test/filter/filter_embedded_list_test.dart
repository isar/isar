// ignore_for_file: hash_and_equals

import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/matchers.dart';
import '../util/sync_async_helper.dart';

part 'filter_embedded_list_test.g.dart';

@collection
class Model {
  Model({
    required this.embeddedAs,
    required this.embeddedBs,
  });

  Id id = Isar.autoIncrement;

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

    setUp(() async {
      isar = await openTempIsar([ModelSchema]);

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

      await isar.tWriteTxn(
        () => isar.models.tPutAll([obj1, obj2, obj3, obj4, obj5, obj6]),
      );
    });

    isarTest('.embeddedIsNull()', () async {
      await qEqualSet(
        isar.models.filter().embeddedBsIsNull(),
        [obj3],
      );
    });

    isarTest('.embeddedIsNotNull()', () async {
      await qEqualSet(
        isar.models.filter().embeddedBsIsNotNull(),
        [obj1, obj2, obj4, obj5, obj6],
      );
    });

    isarTest('.embeddedLengthEqualTo()', () async {
      await qEqualSet(
        isar.models.filter().embeddedAsLengthEqualTo(0),
        [obj4],
      );
      await qEqualSet(
        isar.models.filter().embeddedAsLengthEqualTo(1),
        [obj2, obj3, obj5, obj6],
      );
      await qEqualSet(
        isar.models.filter().embeddedAsLengthEqualTo(3),
        [obj1],
      );
      await qEqualSet(
        isar.models.filter().embeddedAsLengthEqualTo(4),
        [],
      );

      await qEqualSet(
        isar.models.filter().embeddedBsLengthEqualTo(0),
        [obj4],
      );
      await qEqualSet(
        isar.models.filter().embeddedBsLengthEqualTo(1),
        [obj2],
      );
      await qEqualSet(
        isar.models.filter().embeddedBsLengthEqualTo(2),
        [],
      );
      await qEqualSet(
        isar.models.filter().embeddedBsLengthEqualTo(3),
        [obj1, obj6],
      );
      await qEqualSet(
        isar.models.filter().embeddedBsLengthEqualTo(4),
        [],
      );
      await qEqualSet(
        isar.models.filter().embeddedBsLengthEqualTo(5),
        [obj5],
      );
      await qEqualSet(
        isar.models.filter().embeddedBsLengthEqualTo(6),
        [],
      );
    });

    isarTest('.embeddedLengthGreaterThan()', () async {
      await qEqualSet(
        isar.models.filter().embeddedAsLengthGreaterThan(0),
        [obj1, obj2, obj3, obj5, obj6],
      );
      await qEqualSet(
        isar.models.filter().embeddedAsLengthGreaterThan(1),
        [obj1],
      );
      await qEqualSet(
        isar.models.filter().embeddedAsLengthGreaterThan(2),
        [obj1],
      );
      await qEqualSet(
        isar.models.filter().embeddedAsLengthGreaterThan(3, include: true),
        [obj1],
      );
      await qEqualSet(
        isar.models.filter().embeddedAsLengthGreaterThan(3),
        [],
      );

      await qEqualSet(
        isar.models.filter().embeddedBsLengthGreaterThan(0),
        [obj1, obj2, obj5, obj6],
      );
      await qEqualSet(
        isar.models.filter().embeddedBsLengthGreaterThan(1),
        [obj1, obj5, obj6],
      );
      await qEqualSet(
        isar.models.filter().embeddedBsLengthGreaterThan(2),
        [obj1, obj5, obj6],
      );
      await qEqualSet(
        isar.models.filter().embeddedBsLengthGreaterThan(3),
        [obj5],
      );
      await qEqualSet(
        isar.models.filter().embeddedBsLengthGreaterThan(4),
        [obj5],
      );
      await qEqualSet(
        isar.models.filter().embeddedBsLengthGreaterThan(5, include: true),
        [obj5],
      );
      await qEqualSet(
        isar.models.filter().embeddedBsLengthGreaterThan(5),
        [],
      );
    });

    isarTest('.embeddedLengthLessThanThan()', () async {
      await qEqualSet(
        isar.models.filter().embeddedAsLengthLessThan(0),
        [],
      );
      await qEqualSet(
        isar.models.filter().embeddedAsLengthLessThan(1),
        [obj4],
      );
      await qEqualSet(
        isar.models.filter().embeddedAsLengthLessThan(2),
        [obj2, obj3, obj4, obj5, obj6],
      );
      await qEqualSet(
        isar.models.filter().embeddedAsLengthLessThan(3),
        [obj2, obj3, obj4, obj5, obj6],
      );
      await qEqualSet(
        isar.models.filter().embeddedAsLengthLessThan(3),
        [obj2, obj3, obj4, obj5, obj6],
      );
      await qEqualSet(
        isar.models.filter().embeddedAsLengthLessThan(3, include: true),
        [obj1, obj2, obj3, obj4, obj5, obj6],
      );

      await qEqualSet(
        isar.models.filter().embeddedBsLengthLessThan(0),
        [],
      );
      await qEqualSet(
        isar.models.filter().embeddedBsLengthLessThan(1),
        [obj4],
      );
      await qEqualSet(
        isar.models.filter().embeddedBsLengthLessThan(2),
        [obj2, obj4],
      );
      await qEqualSet(
        isar.models.filter().embeddedBsLengthLessThan(3),
        [obj2, obj4],
      );
      await qEqualSet(
        isar.models.filter().embeddedBsLengthLessThan(4),
        [obj1, obj2, obj4, obj6],
      );
      await qEqualSet(
        isar.models.filter().embeddedBsLengthLessThan(5),
        [obj1, obj2, obj4, obj6],
      );
      await qEqualSet(
        isar.models.filter().embeddedBsLengthLessThan(5, include: true),
        [obj1, obj2, obj4, obj5, obj6],
      );
    });

    isarTest('.embeddedLengthBetweenThan()', () async {
      await qEqualSet(
        isar.models.filter().embeddedAsLengthBetween(1, 3),
        [obj1, obj2, obj3, obj5, obj6],
      );
      await qEqualSet(
        isar.models.filter().embeddedAsLengthBetween(3, 4),
        [obj1],
      );
      await qEqualSet(
        isar.models.filter().embeddedAsLengthBetween(10, 12),
        [],
      );

      await qEqualSet(
        isar.models.filter().embeddedBsLengthBetween(1, 3),
        [obj1, obj2, obj6],
      );
      await qEqualSet(
        isar.models.filter().embeddedBsLengthBetween(3, 4),
        [obj1, obj6],
      );
      await qEqualSet(
        isar.models.filter().embeddedBsLengthBetween(10, 12),
        [],
      );
    });

    isarTest('.embeddedIsEmpty()', () async {
      await qEqualSet(
        isar.models.filter().embeddedAsIsEmpty(),
        [obj4],
      );

      await qEqualSet(
        isar.models.filter().embeddedBsIsEmpty(),
        [obj4],
      );
    });

    isarTest('.embeddedIsNotEmpty()', () async {
      await qEqualSet(
        isar.models.filter().embeddedAsIsNotEmpty(),
        [obj1, obj2, obj3, obj5, obj6],
      );

      await qEqualSet(
        isar.models.filter().embeddedBsIsNotEmpty(),
        [obj1, obj2, obj5, obj6],
      );
    });

    // FIXME: IsarError: Unsupported type for condition
    isarTest('.embeddedElementEqualTo()', () async {
      await qEqualSet(
        isar.models.filter().embeddedAsElementEqualTo(obj1.embeddedAs[0]),
        [obj1],
      );
      await qEqualSet(
        isar.models.filter().embeddedAsElementEqualTo(obj1.embeddedAs[1]),
        [obj1],
      );
      await qEqualSet(
        isar.models.filter().embeddedAsElementEqualTo(obj1.embeddedAs[2]),
        [obj1],
      );
      await qEqualSet(
        isar.models.filter().embeddedAsElementEqualTo(obj2.embeddedAs[0]),
        [obj2],
      );
      await qEqualSet(
        isar.models.filter().embeddedAsElementEqualTo(obj3.embeddedAs[0]),
        [obj3],
      );
      await qEqualSet(
        isar.models.filter().embeddedAsElementEqualTo(obj5.embeddedAs[0]),
        [obj5],
      );
      await qEqualSet(
        isar.models.filter().embeddedAsElementEqualTo(obj6.embeddedAs[0]),
        [obj6],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElementEqualTo(EmbeddedA(name: 'non existing')),
        [],
      );

      await qEqualSet(
        isar.models.filter().embeddedBsElementEqualTo(obj1.embeddedBs![0]),
        [obj1],
      );
      await qEqualSet(
        isar.models.filter().embeddedBsElementEqualTo(obj1.embeddedBs![1]),
        [obj1],
      );
      await qEqualSet(
        isar.models.filter().embeddedBsElementEqualTo(obj1.embeddedBs![2]),
        [obj1],
      );
      await qEqualSet(
        isar.models.filter().embeddedBsElementEqualTo(obj5.embeddedBs![0]),
        [obj5],
      );
      await qEqualSet(
        isar.models.filter().embeddedBsElementEqualTo(obj5.embeddedBs![1]),
        [obj5],
      );
      await qEqualSet(
        isar.models.filter().embeddedBsElementEqualTo(obj5.embeddedBs![2]),
        [obj5],
      );
      await qEqualSet(
        isar.models.filter().embeddedBsElementEqualTo(obj5.embeddedBs![3]),
        [obj5],
      );
      await qEqualSet(
        isar.models.filter().embeddedBsElementEqualTo(obj5.embeddedBs![4]),
        [obj5],
      );
      await qEqualSet(
        isar.models.filter().embeddedBsElementEqualTo(obj6.embeddedBs![1]),
        [obj6],
      );
    });

    // FIXME: IsarError: IllegalArg: Property does not support this filter..
    isarTest('.embeddedElementIsNull()', () async {
      await qEqualSet(
        isar.models.filter().embeddedBsElementIsNull(),
        [obj2, obj6],
      );
    });

    // FIXME: IsarError: IllegalArg: Property does not support this filter..
    isarTest('.embeddedElementIsNotNull()', () async {
      await qEqualSet(
        isar.models.filter().embeddedBsElementIsNotNull(),
        [obj1, obj5, obj6],
      );
    });

    isarTest('.embeddedElement()', () async {
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.nameStartsWith('embedded')),
        [obj1, obj2, obj3, obj5, obj6],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.nameEqualTo('embedded a1 - 1')),
        [obj1],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.nameEqualTo('embedded a1 - 2')),
        [obj1],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.nameEqualTo('embedded a1 - 3')),
        [obj1],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.nameEqualTo('embedded a2 - 1')),
        [obj2],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.nameEqualTo('embedded a3 - 1')),
        [obj3],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.nameEqualTo('embedded a5 - 1')),
        [obj5],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.nameEqualTo('embedded a6 - 1')),
        [obj6],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.nameEqualTo('non existing')),
        [],
      );

      await qEqualSet(
        isar.models
            .filter()
            .embeddedBsElement((q) => q.nameStartsWith('embedded')),
        [obj1, obj5, obj6],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedBsElement((q) => q.nameEqualTo('embedded b1 - 1')),
        [obj1],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedBsElement((q) => q.nameEqualTo('embedded b1 - 2')),
        [obj1],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedBsElement((q) => q.nameEqualTo('embedded b1 - 3')),
        [obj1],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedBsElement((q) => q.nameEqualTo('embedded b5 - 1')),
        [obj5],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedBsElement((q) => q.nameEqualTo('embedded b5 - 2')),
        [obj5],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedBsElement((q) => q.nameEqualTo('embedded b5 - 3')),
        [obj5],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedBsElement((q) => q.nameEqualTo('embedded b5 - 4')),
        [obj5],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedBsElement((q) => q.nameEqualTo('embedded b5 - 5')),
        [obj5],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedBsElement((q) => q.nameEqualTo('embedded b6 - 1')),
        [obj6],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedBsElement((q) => q.nameEqualTo('non existing')),
        [],
      );
    });

    isarTest('.embeddedElement() then .embeddedIsNull()', () async {
      await qEqualSet(
        isar.models.filter().embeddedAsElement((q) => q.embeddedBsIsNull()),
        [obj1, obj2],
      );
    });

    isarTest('.embeddedElement() then .embeddedIsNotNull()', () async {
      await qEqualSet(
        isar.models.filter().embeddedAsElement((q) => q.embeddedBsIsNotNull()),
        [obj1, obj3, obj5, obj6],
      );
    });

    isarTest('.embeddedElement() then .embeddedLengthEqualTo()', () async {
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.embeddedBsLengthEqualTo(0)),
        [],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.embeddedBsLengthEqualTo(1)),
        [],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.embeddedBsLengthEqualTo(2)),
        [obj1, obj3],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.embeddedBsLengthEqualTo(3)),
        [obj1],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.embeddedBsLengthEqualTo(4)),
        [obj6],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.embeddedBsLengthEqualTo(5)),
        [obj5],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.embeddedBsLengthEqualTo(6)),
        [],
      );
    });

    isarTest('.embeddedElement() then .embeddedLengthLessThan()', () async {
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.embeddedBsLengthLessThan(0)),
        [],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.embeddedBsLengthLessThan(1)),
        [],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.embeddedBsLengthLessThan(2)),
        [],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.embeddedBsLengthLessThan(3)),
        [obj1, obj3],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.embeddedBsLengthLessThan(4)),
        [obj1, obj3],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.embeddedBsLengthLessThan(5)),
        [obj1, obj3, obj6],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.embeddedBsLengthLessThan(6)),
        [obj1, obj3, obj5, obj6],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.embeddedBsLengthLessThan(7)),
        [obj1, obj3, obj5, obj6],
      );
    });

    isarTest('.embeddedElement() then .embeddedLengthGreaterThan()', () async {
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.embeddedBsLengthGreaterThan(0)),
        [obj1, obj3, obj5, obj6],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.embeddedBsLengthGreaterThan(1)),
        [obj1, obj3, obj5, obj6],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.embeddedBsLengthGreaterThan(2)),
        [obj1, obj5, obj6],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.embeddedBsLengthGreaterThan(3)),
        [obj5, obj6],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.embeddedBsLengthGreaterThan(4)),
        [obj5],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.embeddedBsLengthGreaterThan(5)),
        [],
      );
    });

    isarTest('.embeddedElement() then .embeddedLengthBetween()', () async {
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.embeddedBsLengthBetween(2, 4)),
        [obj1, obj3, obj6],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.embeddedBsLengthBetween(3, 4)),
        [obj1, obj6],
      );
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.embeddedBsLengthBetween(5, 42)),
        [obj5],
      );
    });

    isarTest('.embeddedElement() then .embeddedIsEmpty()', () async {
      await qEqualSet(
        isar.models.filter().embeddedAsElement((q) => q.embeddedBsIsEmpty()),
        [],
      );
    });

    isarTest('.embeddedElement() then .embeddedIsNotEmpty()', () async {
      await qEqualSet(
        isar.models.filter().embeddedAsElement((q) => q.embeddedBsIsNotEmpty()),
        [obj1, obj3, obj5, obj6],
      );
    });

    // FIXME: IsarError: IllegalArg: Property does not support this filter..
    isarTest('.embeddedElement() then .embeddedElementIsNull()', () async {
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.embeddedBsElementIsNull()),
        [obj1, obj3, obj6],
      );
    });

    // FIXME: IsarError: IllegalArg: Property does not support this filter..
    isarTest('.embeddedElement() then .embeddedElementIsNotNull()', () async {
      await qEqualSet(
        isar.models
            .filter()
            .embeddedAsElement((q) => q.embeddedBsElementIsNotNull()),
        [obj1, obj3, obj5, obj6],
      );
    });

    // FIXME: IsarError: Unsupported type for condition
    isarTest('.embeddedElement() then .embeddedElementEqualTo()', () async {
      await qEqualSet(
        isar.models.filter().embeddedAsElement(
              (q) => q.embeddedBsElementEqualTo(
                obj1.embeddedAs[2].embeddedBs![0],
              ),
            ),
        [obj1],
      );
      await qEqualSet(
        isar.models.filter().embeddedAsElement(
              (q) => q.embeddedBsElementEqualTo(
                obj1.embeddedAs[2].embeddedBs![1],
              ),
            ),
        [obj1],
      );
      await qEqualSet(
        isar.models.filter().embeddedAsElement(
              (q) => q.embeddedBsElementEqualTo(
                obj1.embeddedAs[2].embeddedBs![2],
              ),
            ),
        [obj1],
      );

      await qEqualSet(
        isar.models.filter().embeddedAsElement(
              (q) => q.embeddedBsElementEqualTo(
                obj3.embeddedAs[0].embeddedBs![1],
              ),
            ),
        [obj3],
      );

      await qEqualSet(
        isar.models.filter().embeddedAsElement(
              (q) => q.embeddedBsElementEqualTo(
                obj5.embeddedAs[0].embeddedBs![0],
              ),
            ),
        [obj5],
      );
      await qEqualSet(
        isar.models.filter().embeddedAsElement(
              (q) => q.embeddedBsElementEqualTo(
                obj5.embeddedAs[0].embeddedBs![1],
              ),
            ),
        [obj5],
      );
      await qEqualSet(
        isar.models.filter().embeddedAsElement(
              (q) => q.embeddedBsElementEqualTo(
                obj5.embeddedAs[0].embeddedBs![2],
              ),
            ),
        [obj5],
      );
      await qEqualSet(
        isar.models.filter().embeddedAsElement(
              (q) => q.embeddedBsElementEqualTo(
                obj5.embeddedAs[0].embeddedBs![3],
              ),
            ),
        [obj5],
      );
      await qEqualSet(
        isar.models.filter().embeddedAsElement(
              (q) => q.embeddedBsElementEqualTo(
                obj5.embeddedAs[0].embeddedBs![4],
              ),
            ),
        [obj5],
      );

      await qEqualSet(
        isar.models.filter().embeddedAsElement(
              (q) => q.embeddedBsElementEqualTo(
                obj6.embeddedAs[0].embeddedBs![0],
              ),
            ),
        [obj6],
      );

      await qEqualSet(
        isar.models.filter().embeddedAsElement(
              (q) => q.embeddedBsElementEqualTo(
                EmbeddedB(name: 'non existing'),
              ),
            ),
        [],
      );
    });

    // FIXME(severe): panic
    // Shell: thread 'isarworker' panicked at 'range end index 6450588 out of
    // range for slice of length 26', library/core/src/slice/index.rs:73:5
    isarTest('.embeddedElement() then .embeddedElement()', () async {
      await qEqualSet(
        isar.models.filter().embeddedAsElement(
              (q) => q.embeddedBsElement(
                (q) => q.nameStartsWith('embedded'),
              ),
            ),
        [obj1, obj3, obj5, obj6],
      );

      await qEqualSet(
        isar.models.filter().embeddedAsElement(
              (q) => q.embeddedBsElement(
                (q) => q.nameEqualTo('embedded a1 b1 - 1'),
              ),
            ),
        [obj1],
      );
      await qEqualSet(
        isar.models.filter().embeddedAsElement(
              (q) => q.embeddedBsElement(
                (q) => q.nameEqualTo('embedded a1 b1 - 2'),
              ),
            ),
        [obj1],
      );
      await qEqualSet(
        isar.models.filter().embeddedAsElement(
              (q) => q.embeddedBsElement(
                (q) => q.nameEqualTo('embedded a1 b1 - 3'),
              ),
            ),
        [obj1],
      );

      await qEqualSet(
        isar.models.filter().embeddedAsElement(
              (q) => q.embeddedBsElement(
                (q) => q.nameEqualTo('embedded a3 b3 - 1'),
              ),
            ),
        [obj3],
      );

      await qEqualSet(
        isar.models.filter().embeddedAsElement(
              (q) => q.embeddedBsElement(
                (q) => q.nameEqualTo('embedded a5 b5 - 1'),
              ),
            ),
        [obj5],
      );
      await qEqualSet(
        isar.models.filter().embeddedAsElement(
              (q) => q.embeddedBsElement(
                (q) => q.nameEqualTo('embedded a5 b5 - 2'),
              ),
            ),
        [obj5],
      );
      await qEqualSet(
        isar.models.filter().embeddedAsElement(
              (q) => q.embeddedBsElement(
                (q) => q.nameEqualTo('embedded a5 b5 - 3'),
              ),
            ),
        [obj5],
      );
      await qEqualSet(
        isar.models.filter().embeddedAsElement(
              (q) => q.embeddedBsElement(
                (q) => q.nameEqualTo('embedded a5 b5 - 4'),
              ),
            ),
        [obj5],
      );
      await qEqualSet(
        isar.models.filter().embeddedAsElement(
              (q) => q.embeddedBsElement(
                (q) => q.nameEqualTo('embedded a5 b5 - 5'),
              ),
            ),
        [obj5],
      );

      await qEqualSet(
        isar.models.filter().embeddedAsElement(
              (q) => q.embeddedBsElement(
                (q) => q.nameEqualTo('embedded a6 b6 - 1'),
              ),
            ),
        [obj6],
      );

      await qEqualSet(
        isar.models.filter().embeddedAsElement(
              (q) => q.embeddedBsElement(
                (q) => q.nameEqualTo('non existing'),
              ),
            ),
        [],
      );
    });
  });
}
