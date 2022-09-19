import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'filter_link_test.g.dart';

@collection
class SourceModel {
  Id id = Isar.autoIncrement;

  final link = IsarLink<TargetModel>();

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SourceModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  String toString() {
    return 'SourceModel{id: $id, link: $link}';
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
  group('Filter link', () {
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
        () => Future.any([
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
      source4.link.value = target1;

      await isar.tWriteTxn(
        () => Future.value([
          source1.link.tSave(),
          source2.link.tSave(),
          source3.link.tSave(),
          source4.link.tSave(),
        ]),
      );
    });

    isarTest('.link()', () async {
      await qEqualSet(
        isar.sourceModels.filter().link((q) => q.nameContains('target')),
        [source1, source2, source3, source4],
      );

      await qEqualSet(
        isar.sourceModels.filter().link((q) => q.nameEqualTo('target 1')),
        [source1, source4],
      );

      await qEqualSet(
        isar.sourceModels.filter().link((q) => q.nameEqualTo('target 2')),
        [source2],
      );

      await qEqualSet(
        isar.sourceModels.filter().link((q) => q.nameEqualTo('target 3')),
        [source3],
      );

      await qEqualSet(
        isar.sourceModels.filter().link((q) => q.nameEqualTo('target 4')),
        [],
      );

      await qEqualSet(
        isar.sourceModels.filter().link((q) => q.nameEqualTo('target 5')),
        [],
      );

      await qEqualSet(
        isar.sourceModels.filter().link((q) => q.nameEqualTo('target 6')),
        [],
      );

      await qEqualSet(
        isar.sourceModels.filter().link((q) => q.nameEqualTo('non existing')),
        [],
      );

      await qEqualSet(
        isar.sourceModels
            .filter()
            .link((q) => q.nameEqualTo('target 1'))
            .or()
            .link((q) => q.nameEqualTo('target 6')),
        [source1, source4],
      );

      await qEqualSet(
        isar.sourceModels
            .filter()
            .link((q) => q.nameEqualTo('target 3').and().nameContains('3')),
        [source3],
      );

      await qEqualSet(
        isar.sourceModels
            .filter()
            .link((q) => q.nameEqualTo('target 1'))
            .limit(1),
        [source1],
      );
    });

    isarTest('.isNull()', () async {
      await qEqualSet(
        isar.sourceModels.filter().linkIsNull(),
        [source5, source6],
      );

      await isar.tWriteTxn(() => source1.link.tReset());

      await qEqualSet(
        isar.sourceModels.filter().linkIsNull(),
        [source1, source5, source6],
      );

      source6.link.value = target6;
      await isar.tWriteTxn(() => source6.link.tSave());

      await qEqualSet(
        isar.sourceModels.filter().linkIsNull(),
        [source1, source5],
      );

      await isar.tWriteTxn(() => isar.targetModels.where().tDeleteAll());

      await qEqualSet(
        isar.sourceModels.filter().linkIsNull(),
        [source1, source2, source3, source4, source5, source6],
      );
    });
  });
}
