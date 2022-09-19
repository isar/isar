import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'filter_backlink_test.g.dart';

@collection
class SourceModel {
  SourceModel(this.name);

  Id id = Isar.autoIncrement;

  String name;

  final link = IsarLink<TargetModel>();

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

@collection
class TargetModel {
  Id id = Isar.autoIncrement;

  @Backlink(to: 'link')
  final backlink = IsarLink<SourceModel>();

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
  group('Filter backlink', () {
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

      source1.link.value = target1;
      source2.link.value = target2;
      source3.link.value = target3;
      source4.link.value = target4;

      await isar.tWriteTxn(
        () => Future.wait([
          source1.link.tSave(),
          source2.link.tSave(),
          source3.link.tSave(),
          source4.link.tSave(),
        ]),
      );
    });

    isarTest('.backlink()', () async {
      await qEqualSet(
        isar.targetModels.filter().backlink((q) => q.nameEqualTo('source 1')),
        [target1],
      );

      await qEqualSet(
        isar.targetModels.filter().backlink((q) => q.nameEqualTo('source 2')),
        [target2],
      );

      await qEqualSet(
        isar.targetModels.filter().backlink((q) => q.nameEqualTo('source 3')),
        [target3],
      );

      await qEqualSet(
        isar.targetModels.filter().backlink((q) => q.nameEqualTo('source 4')),
        [target4],
      );

      await qEqualSet(
        isar.targetModels.filter().backlink((q) => q.nameEqualTo('source 5')),
        [],
      );

      await qEqualSet(
        isar.targetModels.filter().backlink((q) => q.nameEqualTo('source 6')),
        [],
      );

      await qEqualSet(
        isar.targetModels
            .filter()
            .backlink((q) => q.nameEqualTo('non existing')),
        [],
      );

      await qEqualSet(
        isar.targetModels
            .filter()
            .backlink((q) => q.nameEqualTo('source 1'))
            .or()
            .backlink((q) => q.nameEqualTo('source 4')),
        [target1, target4],
      );
    });

    isarTest('.backlinkIsNull()', () async {
      await qEqualSet(
        isar.targetModels.filter().backlinkIsNull(),
        [target5, target6],
      );

      await isar.tWriteTxn(() => target1.backlink.tReset());

      await qEqualSet(
        isar.targetModels.filter().backlinkIsNull(),
        [target1, target5, target6],
      );

      source6.link.value = target6;
      await isar.tWriteTxn(() => source6.link.tSave());

      await qEqualSet(
        isar.targetModels.filter().backlinkIsNull(),
        [target1, target5],
      );

      await isar.tWriteTxn(() => isar.sourceModels.where().tDeleteAll());

      await qEqualSet(
        isar.targetModels.filter().backlinkIsNull(),
        [target1, target2, target3, target4, target5, target6],
      );
    });
  });
}
