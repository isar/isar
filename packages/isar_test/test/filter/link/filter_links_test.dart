import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'filter_links_test.g.dart';

@collection
class SourceModel {
  Id id = Isar.autoIncrement;

  final links = IsarLinks<TargetModel>();

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SourceModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  String toString() {
    return 'SourceModel{id: $id, links: $links}';
  }
}

@collection
class TargetModel {
  TargetModel(this.name);

  Id id = Isar.autoIncrement;

  String name;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TargetModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  String toString() {
    return 'TargetModel{id: $id, name: $name}';
  }
}

void main() {
  group('Filter links', () {
    late Isar isar;

    late SourceModel source1;
    late SourceModel source2;
    late SourceModel source3;
    late SourceModel source4;
    late SourceModel source5;
    late SourceModel source6;

    late TargetModel target1;
    late TargetModel target2;
    late TargetModel target3;
    late TargetModel target4;
    late TargetModel target5;
    late TargetModel target6;

    setUp(() async {
      isar = await openTempIsar([SourceModelSchema, TargetModelSchema]);

      source1 = SourceModel();
      source2 = SourceModel();
      source3 = SourceModel();
      source4 = SourceModel();
      source5 = SourceModel();
      source6 = SourceModel();

      target1 = TargetModel('target 1');
      target2 = TargetModel('target 2');
      target3 = TargetModel('target 3');
      target4 = TargetModel('target 4');
      target5 = TargetModel('target 5');
      target6 = TargetModel('target 6');

      await isar.tWriteTxn(
        () => Future.wait([
          isar.sourceModels.tPutAll([
            source1,
            source2,
            source3,
            source4,
            source5,
            source6,
          ]),
          isar.targetModels.tPutAll([
            target1,
            target2,
            target3,
            target4,
            target5,
            target6,
          ]),
        ]),
      );

      source1.links.add(target1);
      source2.links.addAll([target1, target2, target3]);
      source3.links.add(target2);
      source4.links.addAll([target4, target2]);

      await isar.tWriteTxn(
        () => Future.wait([
          source1.links.tSave(),
          source2.links.tSave(),
          source3.links.tSave(),
          source4.links.tSave(),
        ]),
      );
    });

    isarTest('.links()', () async {
      await qEqualSet(
        isar.sourceModels.filter().links((q) => q.nameStartsWith('target')),
        [source1, source2, source3, source4],
      );

      await qEqualSet(
        isar.sourceModels.filter().links((q) => q.nameEqualTo('target 1')),
        [source1, source2],
      );

      await qEqualSet(
        isar.sourceModels.filter().links((q) => q.nameEqualTo('target 2')),
        [source2, source3, source4],
      );

      await qEqualSet(
        isar.sourceModels.filter().links((q) => q.nameEqualTo('target 3')),
        [source2],
      );

      await qEqualSet(
        isar.sourceModels.filter().links((q) => q.nameEqualTo('target 4')),
        [source4],
      );

      await qEqualSet(
        isar.sourceModels.filter().links((q) => q.nameEqualTo('target 5')),
        [],
      );

      await qEqualSet(
        isar.sourceModels.filter().links((q) => q.nameEqualTo('target 6')),
        [],
      );

      await qEqualSet(
        isar.sourceModels.filter().links((q) => q.nameEqualTo('non existing')),
        [],
      );

      await qEqualSet(
        isar.sourceModels
            .filter()
            .links(
              (q) => q.nameEqualTo('target 1').or().nameEqualTo('target 2'),
            )
            .and()
            .links((q) => q.nameEqualTo('target 1')),
        [source1, source2],
      );
    });

    isarTest('.linksLengthEqualTo()', () async {
      expect(
        () => isar.sourceModels.filter().linksLengthEqualTo(-1),
        throwsAssertionError,
      );

      await qEqualSet(
        isar.sourceModels.filter().linksLengthEqualTo(0),
        [source5, source6],
      );

      await qEqualSet(
        isar.sourceModels.filter().linksLengthEqualTo(1),
        [source1, source3],
      );

      await qEqualSet(
        isar.sourceModels.filter().linksLengthEqualTo(2),
        [source4],
      );

      await qEqualSet(
        isar.sourceModels.filter().linksLengthEqualTo(3),
        [source2],
      );

      await qEqualSet(
        isar.sourceModels.filter().linksLengthEqualTo(4),
        [],
      );

      await qEqualSet(
        isar.sourceModels.filter().linksLengthEqualTo(5),
        [],
      );
    });

    isarTest('.linksLengthGreaterThan()', () async {
      expect(
        () => isar.sourceModels.filter().linksLengthGreaterThan(-2),
        throwsAssertionError,
      );

      await qEqualSet(
        isar.sourceModels.filter().linksLengthGreaterThan(0),
        [source1, source2, source3, source4],
      );
      await qEqualSet(
        isar.sourceModels.filter().linksLengthGreaterThan(0, include: true),
        [source1, source2, source3, source4, source5, source6],
      );

      await qEqualSet(
        isar.sourceModels.filter().linksLengthGreaterThan(1),
        [source2, source4],
      );
      await qEqualSet(
        isar.sourceModels.filter().linksLengthGreaterThan(1, include: true),
        [source1, source2, source3, source4],
      );

      await qEqualSet(
        isar.sourceModels.filter().linksLengthGreaterThan(2),
        [source2],
      );
      await qEqualSet(
        isar.sourceModels.filter().linksLengthGreaterThan(2, include: true),
        [source2, source4],
      );

      await qEqualSet(
        isar.sourceModels.filter().linksLengthGreaterThan(3),
        [],
      );
      await qEqualSet(
        isar.sourceModels.filter().linksLengthGreaterThan(3, include: true),
        [source2],
      );
    });

    isarTest('.linksLengthLessThan()', () async {
      expect(
        () => isar.sourceModels.filter().linksLengthLessThan(-1),
        throwsAssertionError,
      );

      await qEqualSet(
        isar.sourceModels.filter().linksLengthLessThan(0),
        [],
      );
      await qEqualSet(
        isar.sourceModels.filter().linksLengthLessThan(0, include: true),
        [source5, source6],
      );

      await qEqualSet(
        isar.sourceModels.filter().linksLengthLessThan(1),
        [source5, source6],
      );
      await qEqualSet(
        isar.sourceModels.filter().linksLengthLessThan(1, include: true),
        [source1, source3, source5, source6],
      );

      await qEqualSet(
        isar.sourceModels.filter().linksLengthLessThan(2),
        [source1, source3, source5, source6],
      );
      await qEqualSet(
        isar.sourceModels.filter().linksLengthLessThan(2, include: true),
        [source1, source3, source4, source5, source6],
      );

      await qEqualSet(
        isar.sourceModels.filter().linksLengthLessThan(3),
        [source1, source3, source4, source5, source6],
      );
      await qEqualSet(
        isar.sourceModels.filter().linksLengthLessThan(3, include: true),
        [source1, source2, source3, source4, source5, source6],
      );

      await qEqualSet(
        isar.sourceModels.filter().linksLengthLessThan(9223372036854775807),
        [source1, source2, source3, source4, source5, source6],
      );
    });

    isarTest('.linksLengthBetween()', () async {
      await qEqualSet(
        isar.sourceModels.filter().linksLengthBetween(0, 3),
        [source1, source2, source3, source4, source5, source6],
      );

      await qEqualSet(
        isar.sourceModels
            .filter()
            .linksLengthBetween(0, 3, includeLower: false),
        [source1, source2, source3, source4],
      );

      await qEqualSet(
        isar.sourceModels
            .filter()
            .linksLengthBetween(0, 3, includeUpper: false),
        [source1, source3, source4, source5, source6],
      );

      await qEqualSet(
        isar.sourceModels
            .filter()
            .linksLengthBetween(0, 3, includeLower: false, includeUpper: false),
        [source1, source3, source4],
      );

      await qEqualSet(
        isar.sourceModels.filter().linksLengthBetween(1, 2),
        [source1, source3, source4],
      );

      await qEqualSet(
        isar.sourceModels.filter().linksLengthBetween(3, 42),
        [source2],
      );
    });

    isarTest('.linksIsEmpty', () async {
      await qEqualSet(
        isar.sourceModels.filter().linksIsEmpty(),
        [source5, source6],
      );

      await isar.tWriteTxn(() => source1.links.tReset());

      await qEqualSet(
        isar.sourceModels.filter().linksIsEmpty(),
        [source1, source5, source6],
      );

      await isar.tWriteTxn(() => isar.targetModels.where().tDeleteAll());

      await qEqualSet(
        isar.sourceModels.filter().linksIsEmpty(),
        [source1, source2, source3, source4, source5, source6],
      );
    });
  });
}
