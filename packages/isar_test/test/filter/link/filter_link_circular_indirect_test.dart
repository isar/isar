import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../../util/common.dart';
import '../../util/sync_async_helper.dart';

part 'filter_link_circular_indirect_test.g.dart';

@Collection()
class ModelA {
  ModelA(this.name);

  Id id = Isar.autoIncrement;

  String name;

  final bLinks = IsarLinks<ModelB>();

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModelA &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  String toString() {
    return 'ModelA{id: $id, name: $name}';
  }
}

@Collection()
class ModelB {
  ModelB(this.name);

  Id id = Isar.autoIncrement;

  String name;

  final cLinks = IsarLinks<ModelC>();

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModelB &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  String toString() {
    return 'ModelB{id: $id, name: $name}';
  }
}

@Collection()
class ModelC {
  ModelC(this.name);

  Id id = Isar.autoIncrement;

  String name;

  final aLinks = IsarLinks<ModelA>();

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModelC &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  String toString() {
    return 'ModelC{id: $id, name: $name}';
  }
}

void main() {
  group('Filter link circular indirect', () {
    late Isar isar;

    late ModelA a1;
    late ModelA a2;
    late ModelA a3;
    late ModelA a4;
    late ModelA a5;
    late ModelA a6;

    late ModelB b1;
    late ModelB b2;
    late ModelB b3;
    late ModelB b4;
    late ModelB b5;
    late ModelB b6;

    late ModelC c1;
    late ModelC c2;
    late ModelC c3;
    late ModelC c4;
    late ModelC c5;
    late ModelC c6;

    setUp(() async {
      isar = await openTempIsar([ModelASchema, ModelBSchema, ModelCSchema]);

      a1 = ModelA('a 1');
      a2 = ModelA('a 2');
      a3 = ModelA('a 3');
      a4 = ModelA('a 4');
      a5 = ModelA('a 5');
      a6 = ModelA('a 6');

      b1 = ModelB('b 1');
      b2 = ModelB('b 2');
      b3 = ModelB('b 3');
      b4 = ModelB('b 4');
      b5 = ModelB('b 5');
      b6 = ModelB('b 6');

      c1 = ModelC('a 1');
      c2 = ModelC('a 2');
      c3 = ModelC('a 3');
      c4 = ModelC('a 4');
      c5 = ModelC('a 5');
      c6 = ModelC('a 6');

      await isar.tWriteTxn(
        () => Future.wait([
          isar.modelAs.tPutAll([a1, a2, a3, a4, a5, a6]),
          isar.modelBs.tPutAll([b1, b2, b3, b4, b5, b6]),
          isar.modelCs.tPutAll([c1, c2, c3, c4, c5, c6]),
        ]),
      );

      a1.bLinks.add(b1);
      a2.bLinks.addAll([b1, b2]);
      a3.bLinks.addAll([b1, b2, b3]);
      a4.bLinks.addAll([b3, b4]);
      a5.bLinks.add(b5);

      b1.cLinks.add(c1);
      b2.cLinks.addAll([c1, c2]);
      b3.cLinks.addAll([c1, c2, c3]);
      b4.cLinks.addAll([c3, c4]);
      b6.cLinks.add(c6);

      c1.aLinks.add(a1);
      c2.aLinks.addAll([a1, a2]);
      c3.aLinks.addAll([a1, a2, a3]);
      c4.aLinks.addAll([a3, a4]);
      c5.aLinks.add(a6);

      await isar.tWriteTxn(
        () => Future.wait([
          a1.bLinks.tSave(),
          a2.bLinks.tSave(),
          a3.bLinks.tSave(),
          a4.bLinks.tSave(),
          a5.bLinks.tSave(),
          b1.cLinks.tSave(),
          b2.cLinks.tSave(),
          b3.cLinks.tSave(),
          b4.cLinks.tSave(),
          b6.cLinks.tSave(),
          c1.aLinks.tSave(),
          c2.aLinks.tSave(),
          c3.aLinks.tSave(),
          c4.aLinks.tSave(),
          c5.aLinks.tSave(),
        ]),
      );
    });

    // FIXME: Nested filter link (see filter_link_nested_test.dart)
    isarTest('.bLinks() then .cLinks() then .aLinks()', () async {
      await qEqualSet(
        isar.modelAs
            .filter()
            .bLinks(
              (q) => q.cLinks(
                (q) => q.aLinks(
                  (q) => q.nameStartsWith('a'),
                ),
              ),
            )
            .tFindAll(),
        [a1, a2, a3, a4],
      );

      await qEqualSet(
        isar.modelAs
            .filter()
            .bLinks(
              (q) => q.cLinks(
                (q) => q.aLinks(
                  (q) => q.nameEqualTo('a 1'),
                ),
              ),
            )
            .tFindAll(),
        [a1, a2, a3, a4],
      );

      await qEqualSet(
        isar.modelAs
            .filter()
            .bLinks(
              (q) => q.cLinks(
                (q) => q.aLinks(
                  (q) => q.nameEqualTo('a 2'),
                ),
              ),
            )
            .tFindAll(),
        [a2, a3, a4],
      );

      await qEqualSet(
        isar.modelAs
            .filter()
            .bLinks(
              (q) => q.cLinks(
                (q) => q.aLinks(
                  (q) => q.nameEqualTo('a 3'),
                ),
              ),
            )
            .tFindAll(),
        [a3, a4],
      );

      await qEqualSet(
        isar.modelAs
            .filter()
            .bLinks(
              (q) => q.cLinks(
                (q) => q.aLinks(
                  (q) => q.nameEqualTo('a 4'),
                ),
              ),
            )
            .tFindAll(),
        [a4],
      );

      await qEqualSet(
        isar.modelAs
            .filter()
            .bLinks(
              (q) => q.cLinks(
                (q) => q.aLinks(
                  (q) => q.nameEqualTo('a 5'),
                ),
              ),
            )
            .tFindAll(),
        [],
      );

      await qEqualSet(
        isar.modelAs
            .filter()
            .bLinks(
              (q) => q.cLinks(
                (q) => q.aLinks(
                  (q) => q.nameEqualTo('a 6'),
                ),
              ),
            )
            .tFindAll(),
        [],
      );

      await qEqualSet(
        isar.modelAs
            .filter()
            .bLinks(
              (q) => q.cLinks(
                (q) => q.aLinks(
                  (q) => q.nameEqualTo('non existing'),
                ),
              ),
            )
            .tFindAll(),
        [],
      );
    });

    // FIXME: Nested filter link (see filter_link_nested_test.dart)
    isarTest('.cLinks() then .aLinks() then .bLinks()', () async {
      await qEqualSet(
        isar.modelBs
            .filter()
            .cLinks(
              (q) => q.aLinks(
                (q) => q.bLinks(
                  (q) => q.nameStartsWith('b'),
                ),
              ),
            )
            .tFindAll(),
        [b1, b2, b3, b4],
      );

      await qEqualSet(
        isar.modelBs
            .filter()
            .cLinks(
              (q) => q.aLinks(
                (q) => q.bLinks(
                  (q) => q.nameEqualTo('b 1'),
                ),
              ),
            )
            .tFindAll(),
        [b1, b2, b3, b4],
      );

      await qEqualSet(
        isar.modelBs
            .filter()
            .cLinks(
              (q) => q.aLinks(
                (q) => q.bLinks(
                  (q) => q.nameEqualTo('b 2'),
                ),
              ),
            )
            .tFindAll(),
        [b2, b3, b4],
      );

      await qEqualSet(
        isar.modelBs
            .filter()
            .cLinks(
              (q) => q.aLinks(
                (q) => q.bLinks(
                  (q) => q.nameEqualTo('b 3'),
                ),
              ),
            )
            .tFindAll(),
        [b3, b4],
      );

      await qEqualSet(
        isar.modelBs
            .filter()
            .cLinks(
              (q) => q.aLinks(
                (q) => q.bLinks(
                  (q) => q.nameEqualTo('b 4'),
                ),
              ),
            )
            .tFindAll(),
        [b4],
      );

      await qEqualSet(
        isar.modelBs
            .filter()
            .cLinks(
              (q) => q.aLinks(
                (q) => q.bLinks(
                  (q) => q.nameEqualTo('b 5'),
                ),
              ),
            )
            .tFindAll(),
        [],
      );

      await qEqualSet(
        isar.modelBs
            .filter()
            .cLinks(
              (q) => q.aLinks(
                (q) => q.bLinks(
                  (q) => q.nameEqualTo('b 6'),
                ),
              ),
            )
            .tFindAll(),
        [],
      );

      await qEqualSet(
        isar.modelBs
            .filter()
            .cLinks(
              (q) => q.aLinks(
                (q) => q.bLinks(
                  (q) => q.nameEqualTo('non existing'),
                ),
              ),
            )
            .tFindAll(),
        [],
      );
    });

    // FIXME: Nested filter link (see filter_link_nested_test.dart)
    isarTest('.aLinks() then .bLinks() then .cLinks()', () async {
      await qEqualSet(
        isar.modelCs
            .filter()
            .aLinks(
              (q) => q.bLinks(
                (q) => q.cLinks(
                  (q) => q.nameStartsWith('c'),
                ),
              ),
            )
            .tFindAll(),
        [c1, c2, c3, c4],
      );

      await qEqualSet(
        isar.modelCs
            .filter()
            .aLinks(
              (q) => q.bLinks(
                (q) => q.cLinks(
                  (q) => q.nameEqualTo('c 1'),
                ),
              ),
            )
            .tFindAll(),
        [c1, c2, c3, c4],
      );

      await qEqualSet(
        isar.modelCs
            .filter()
            .aLinks(
              (q) => q.bLinks(
                (q) => q.cLinks(
                  (q) => q.nameEqualTo('c 2'),
                ),
              ),
            )
            .tFindAll(),
        [c2, c3, c4],
      );

      await qEqualSet(
        isar.modelCs
            .filter()
            .aLinks(
              (q) => q.bLinks(
                (q) => q.cLinks(
                  (q) => q.nameEqualTo('c 3'),
                ),
              ),
            )
            .tFindAll(),
        [c3, c4],
      );

      await qEqualSet(
        isar.modelCs
            .filter()
            .aLinks(
              (q) => q.bLinks(
                (q) => q.cLinks(
                  (q) => q.nameEqualTo('c 4'),
                ),
              ),
            )
            .tFindAll(),
        [c4],
      );

      await qEqualSet(
        isar.modelCs
            .filter()
            .aLinks(
              (q) => q.bLinks(
                (q) => q.cLinks(
                  (q) => q.nameEqualTo('c 5'),
                ),
              ),
            )
            .tFindAll(),
        [],
      );

      await qEqualSet(
        isar.modelCs
            .filter()
            .aLinks(
              (q) => q.bLinks(
                (q) => q.cLinks(
                  (q) => q.nameEqualTo('c 6'),
                ),
              ),
            )
            .tFindAll(),
        [],
      );

      await qEqualSet(
        isar.modelCs
            .filter()
            .aLinks(
              (q) => q.bLinks(
                (q) => q.cLinks(
                  (q) => q.nameEqualTo('non existing'),
                ),
              ),
            )
            .tFindAll(),
        [],
      );
    });
  });
}
