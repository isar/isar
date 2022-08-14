import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../../util/common.dart';
import '../../util/sync_async_helper.dart';

part 'filter_backlinks_test.g.dart';

@Collection()
class SourceModel {
  SourceModel(this.name);

  Id id = Isar.autoIncrement;

  String name;

  final links = IsarLinks<TargetModel>();

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SourceModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  String toString() {
    return 'SourceModel{id: $id, name: $name}';
  }
}

@Collection()
class TargetModel {
  Id id = Isar.autoIncrement;

  @Backlink(to: 'links')
  final backlinks = IsarLinks<SourceModel>();

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TargetModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  String toString() {
    return 'TargetModel{id: $id}';
  }
}

void main() {
  group('Filter backlinks', () {
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

      source1 = SourceModel('source 1');
      source2 = SourceModel('source 2');
      source3 = SourceModel('source 3');
      source4 = SourceModel('source 4');
      source5 = SourceModel('source 5');
      source6 = SourceModel('source 6');

      target1 = TargetModel();
      target2 = TargetModel();
      target3 = TargetModel();
      target4 = TargetModel();
      target5 = TargetModel();
      target6 = TargetModel();

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
      source2.links.addAll([target1, target2]);
      source3.links.addAll([target1, target2, target3]);
      source4.links.add(target4);

      await isar.tWriteTxn(
        () => Future.wait([
          source1.links.tSave(),
          source2.links.tSave(),
          source3.links.tSave(),
          source4.links.tSave(),
        ]),
      );
    });

    isarTest('.backlinks()', () async {
      await qEqualSet(
        isar.targetModels
            .filter()
            .backlinks((q) => q.nameStartsWith('source'))
            .tFindAll(),
        [target1, target2, target3, target4],
      );

      await qEqualSet(
        isar.targetModels
            .filter()
            .backlinks((q) => q.nameEqualTo('source 1'))
            .tFindAll(),
        [target1],
      );

      await qEqualSet(
        isar.targetModels
            .filter()
            .backlinks((q) => q.nameEqualTo('source 2'))
            .tFindAll(),
        [target1, target2],
      );

      await qEqualSet(
        isar.targetModels
            .filter()
            .backlinks((q) => q.nameEqualTo('source 3'))
            .tFindAll(),
        [target1, target2, target3],
      );

      await qEqualSet(
        isar.targetModels
            .filter()
            .backlinks((q) => q.nameEqualTo('source 4'))
            .tFindAll(),
        [target4],
      );

      await qEqualSet(
        isar.targetModels
            .filter()
            .backlinks((q) => q.nameEqualTo('source 5'))
            .tFindAll(),
        [],
      );

      await qEqualSet(
        isar.targetModels
            .filter()
            .backlinks((q) => q.nameEqualTo('source 6'))
            .tFindAll(),
        [],
      );

      await qEqualSet(
        isar.targetModels
            .filter()
            .backlinks((q) => q.nameEqualTo('non existing'))
            .tFindAll(),
        [],
      );

      await qEqualSet(
        isar.targetModels
            .filter()
            .backlinks(
              (q) => q.nameEqualTo('source 1').or().nameEqualTo('source 2'),
            )
            .and()
            .backlinks((q) => q.nameEqualTo('source 1'))
            .tFindAll(),
        [target1],
      );
    });

    isarTest('.backlinksLengthEqualTo()', () async {
      await qEqualSet(
        isar.targetModels.filter().backlinksLengthEqualTo(-1).tFindAll(),
        [],
      );

      await qEqualSet(
        isar.targetModels.filter().backlinksLengthEqualTo(0).tFindAll(),
        [target5, target6],
      );

      await qEqualSet(
        isar.targetModels.filter().backlinksLengthEqualTo(1).tFindAll(),
        [target3, target4],
      );

      await qEqualSet(
        isar.targetModels.filter().backlinksLengthEqualTo(2).tFindAll(),
        [target2],
      );

      await qEqualSet(
        isar.targetModels.filter().backlinksLengthEqualTo(3).tFindAll(),
        [target1],
      );

      await qEqualSet(
        isar.targetModels.filter().backlinksLengthEqualTo(4).tFindAll(),
        [],
      );

      await qEqualSet(
        isar.targetModels.filter().backlinksLengthEqualTo(5).tFindAll(),
        [],
      );
    });

    isarTest('.backlinksLengthGreaterThan()', () async {
      await qEqualSet(
        isar.targetModels.filter().backlinksLengthGreaterThan(-1).tFindAll(),
        [target1, target2, target3, target4, target5, target6],
      );

      await qEqualSet(
        isar.targetModels.filter().backlinksLengthGreaterThan(0).tFindAll(),
        [target1, target2, target3, target4],
      );
      await qEqualSet(
        isar.targetModels
            .filter()
            .backlinksLengthGreaterThan(0, include: true)
            .tFindAll(),
        [target1, target2, target3, target4, target5, target6],
      );

      await qEqualSet(
        isar.targetModels.filter().backlinksLengthGreaterThan(1).tFindAll(),
        [target1, target2],
      );
      await qEqualSet(
        isar.targetModels
            .filter()
            .backlinksLengthGreaterThan(1, include: true)
            .tFindAll(),
        [target1, target2, target3, target4],
      );

      await qEqualSet(
        isar.targetModels.filter().backlinksLengthGreaterThan(2).tFindAll(),
        [target1],
      );
      await qEqualSet(
        isar.targetModels
            .filter()
            .backlinksLengthGreaterThan(2, include: true)
            .tFindAll(),
        [target1, target2],
      );

      await qEqualSet(
        isar.targetModels.filter().backlinksLengthGreaterThan(3).tFindAll(),
        [],
      );
      await qEqualSet(
        isar.targetModels
            .filter()
            .backlinksLengthGreaterThan(3, include: true)
            .tFindAll(),
        [target1],
      );
    });

    isarTest('.backlinksLengthLessThan()', () async {
      await qEqualSet(
        isar.targetModels.filter().backlinksLengthLessThan(0).tFindAll(),
        [],
      );
      await qEqualSet(
        isar.targetModels
            .filter()
            .backlinksLengthLessThan(0, include: true)
            .tFindAll(),
        [target5, target6],
      );

      await qEqualSet(
        isar.targetModels.filter().backlinksLengthLessThan(1).tFindAll(),
        [target5, target6],
      );
      await qEqualSet(
        isar.targetModels
            .filter()
            .backlinksLengthLessThan(1, include: true)
            .tFindAll(),
        [target3, target4, target5, target6],
      );

      await qEqualSet(
        isar.targetModels.filter().backlinksLengthLessThan(2).tFindAll(),
        [target3, target4, target5, target6],
      );
      await qEqualSet(
        isar.targetModels
            .filter()
            .backlinksLengthLessThan(2, include: true)
            .tFindAll(),
        [target2, target3, target4, target5, target6],
      );

      await qEqualSet(
        isar.targetModels.filter().backlinksLengthLessThan(3).tFindAll(),
        [target2, target3, target4, target5, target6],
      );
      await qEqualSet(
        isar.targetModels
            .filter()
            .backlinksLengthLessThan(3, include: true)
            .tFindAll(),
        [target1, target2, target3, target4, target5, target6],
      );
    });

    isarTest('.backlinksLengthBetween()', () async {
      await qEqualSet(
        isar.targetModels.filter().backlinksLengthBetween(0, 3).tFindAll(),
        [target1, target2, target3, target4, target5, target6],
      );

      await qEqualSet(
        isar.targetModels
            .filter()
            .backlinksLengthBetween(0, 3, includeLower: false)
            .tFindAll(),
        [target1, target2, target3, target4],
      );

      await qEqualSet(
        isar.targetModels
            .filter()
            .backlinksLengthBetween(0, 3, includeUpper: false)
            .tFindAll(),
        [target2, target3, target4, target5, target6],
      );

      await qEqualSet(
        isar.targetModels
            .filter()
            .backlinksLengthBetween(
              0,
              3,
              includeLower: false,
              includeUpper: false,
            )
            .tFindAll(),
        [target2, target3, target4],
      );

      await qEqualSet(
        isar.targetModels.filter().backlinksLengthBetween(1, 2).tFindAll(),
        [target2, target3, target4],
      );

      await qEqualSet(
        isar.targetModels.filter().backlinksLengthBetween(3, 42).tFindAll(),
        [target1],
      );
    });

    isarTest('.backlinksIsEmpty()', () async {
      await qEqualSet(
        isar.targetModels.filter().backlinksIsEmpty().tFindAll(),
        [target5, target6],
      );

      // FIXME: IsarError: Cannot perform this operation from within an active
      // transaction.
      // Are we suppose to a able to reset backlinks?
      // await isar.tWriteTxn(() => target1.backlinks.tReset());

      // await qEqualSet(
      //   isar.targetModels.filter().backlinksIsEmpty().tFindAll(),
      //   [target1, target5, target6],
      // );

      await isar.tWriteTxn(() => isar.sourceModels.where().tDeleteAll());

      await qEqualSet(
        isar.targetModels.filter().backlinksIsEmpty().tFindAll(),
        [target1, target2, target3, target4, target5, target6],
      );
    });

    isarTest('.backlinksIsNotEmpty()', () async {
      await qEqualSet(
        isar.targetModels.filter().backlinksIsNotEmpty().tFindAll(),
        [target1, target2, target3, target4],
      );

      // FIXME: IsarError: Cannot perform this operation from within an active
      // transaction.
      // Are we suppose to a able to reset backlinks?
      // await isar.tWriteTxn(() => target1.backlinks.tReset());

      // await qEqualSet(
      //   isar.targetModels.filter().backlinksIsNotEmpty().tFindAll(),
      //   [target2, target3, target4],
      // );

      await isar.tWriteTxn(() => isar.targetModels.where().tDeleteAll());

      await qEqualSet(
        isar.targetModels.filter().backlinksIsNotEmpty().tFindAll(),
        [],
      );
    });
  });
}
