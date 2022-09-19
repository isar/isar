import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'filter_link_circular_direct_test.g.dart';

@collection
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

@collection
class ModelB {
  ModelB(this.name);

  Id id = Isar.autoIncrement;

  String name;

  final aLinks = IsarLinks<ModelA>();

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

void main() {
  group('Filter link circular direct', () {
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

    setUp(() async {
      isar = await openTempIsar([ModelASchema, ModelBSchema]);

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

      await isar.tWriteTxn(
        () => Future.any([
          isar.modelAs.tPutAll([a1, a2, a3, a4, a5, a6]),
          isar.modelBs.tPutAll([b1, b2, b3, b4, b5, b6]),
        ]),
      );

      a1.bLinks.add(b1);
      a2.bLinks.addAll([b1, b2]);
      a3.bLinks.addAll([b1, b2, b3]);
      a4.bLinks.addAll([b3, b4]);
      a5.bLinks.add(b5);

      b1.aLinks.add(a1);
      b2.aLinks.addAll([a1, a2]);
      b3.aLinks.addAll([a1, a2, a3]);
      b4.aLinks.addAll([a3, a4]);
      b6.aLinks.add(a6);

      await isar.tWriteTxn(
        () => Future.wait([
          a1.bLinks.tSave(),
          a2.bLinks.tSave(),
          a3.bLinks.tSave(),
          a4.bLinks.tSave(),
          a5.bLinks.tSave(),
          b1.aLinks.tSave(),
          b2.aLinks.tSave(),
          b3.aLinks.tSave(),
          b4.aLinks.tSave(),
          b6.aLinks.tSave(),
        ]),
      );
    });

    group('From ModelA', () {
      isarTest('.bLinks()', () async {
        await qEqualSet(
          isar.modelAs.filter().bLinks((q) => q.nameStartsWith('b')),
          [a1, a2, a3, a4, a5],
        );

        await qEqualSet(
          isar.modelAs.filter().bLinks((q) => q.nameStartsWith('b 1')),
          [a1, a2, a3],
        );

        await qEqualSet(
          isar.modelAs.filter().bLinks((q) => q.nameStartsWith('b 2')),
          [a2, a3],
        );

        await qEqualSet(
          isar.modelAs.filter().bLinks((q) => q.nameStartsWith('b 3')),
          [a3, a4],
        );

        await qEqualSet(
          isar.modelAs.filter().bLinks((q) => q.nameStartsWith('b 4')),
          [a4],
        );

        await qEqualSet(
          isar.modelAs.filter().bLinks((q) => q.nameStartsWith('b 5')),
          [a5],
        );

        await qEqualSet(
          isar.modelAs.filter().bLinks((q) => q.nameStartsWith('b 6')),
          [],
        );

        await qEqualSet(
          isar.modelAs.filter().bLinks((q) => q.nameStartsWith('non existing')),
          [],
        );
      });

      isarTest('.bLinks() then .aLinks()', () async {
        await qEqualSet(
          isar.modelAs
              .filter()
              .bLinks((q) => q.aLinks((q) => q.nameStartsWith('a'))),
          [a1, a2, a3, a4],
        );

        await qEqualSet(
          isar.modelAs
              .filter()
              .bLinks((q) => q.aLinks((q) => q.nameStartsWith('a 1'))),
          [a1, a2, a3, a4],
        );

        await qEqualSet(
          isar.modelAs
              .filter()
              .bLinks((q) => q.aLinks((q) => q.nameStartsWith('a 2'))),
          [a2, a3, a4],
        );

        await qEqualSet(
          isar.modelAs
              .filter()
              .bLinks((q) => q.aLinks((q) => q.nameStartsWith('a 3'))),
          [a3, a4],
        );

        await qEqualSet(
          isar.modelAs
              .filter()
              .bLinks((q) => q.aLinks((q) => q.nameStartsWith('a 4'))),
          [a4],
        );

        await qEqualSet(
          isar.modelAs
              .filter()
              .bLinks((q) => q.aLinks((q) => q.nameStartsWith('a 5'))),
          [],
        );

        await qEqualSet(
          isar.modelAs
              .filter()
              .bLinks((q) => q.aLinks((q) => q.nameStartsWith('a 6'))),
          [],
        );

        await qEqualSet(
          isar.modelAs
              .filter()
              .bLinks((q) => q.aLinks((q) => q.nameStartsWith('non existing'))),
          [],
        );
      });

      isarTest('.bLinks() then .aLinks() then .bLinks()', () async {
        await qEqualSet(
          isar.modelAs.filter().bLinks(
                (q) => q.aLinks(
                  (q) => q.bLinks(
                    (q) => q.nameStartsWith('b'),
                  ),
                ),
              ),
          [a1, a2, a3, a4],
        );

        await qEqualSet(
          isar.modelAs.filter().bLinks(
                (q) => q.aLinks(
                  (q) => q.bLinks(
                    (q) => q.nameStartsWith('b 1'),
                  ),
                ),
              ),
          [a1, a2, a3, a4],
        );

        await qEqualSet(
          isar.modelAs.filter().bLinks(
                (q) => q.aLinks(
                  (q) => q.bLinks(
                    (q) => q.nameStartsWith('b 2'),
                  ),
                ),
              ),
          [a2, a3, a4],
        );

        await qEqualSet(
          isar.modelAs.filter().bLinks(
                (q) => q.aLinks(
                  (q) => q.bLinks(
                    (q) => q.nameStartsWith('b 3'),
                  ),
                ),
              ),
          [a3, a4],
        );

        await qEqualSet(
          isar.modelAs.filter().bLinks(
                (q) => q.aLinks(
                  (q) => q.bLinks(
                    (q) => q.nameStartsWith('b 4'),
                  ),
                ),
              ),
          [a4],
        );

        await qEqualSet(
          isar.modelAs.filter().bLinks(
                (q) => q.aLinks(
                  (q) => q.bLinks(
                    (q) => q.nameStartsWith('b 5'),
                  ),
                ),
              ),
          [],
        );

        await qEqualSet(
          isar.modelAs.filter().bLinks(
                (q) => q.aLinks(
                  (q) => q.bLinks(
                    (q) => q.nameStartsWith('b 6'),
                  ),
                ),
              ),
          [],
        );

        await qEqualSet(
          isar.modelAs.filter().bLinks(
                (q) => q.aLinks(
                  (q) => q.bLinks(
                    (q) => q.nameStartsWith('non existing'),
                  ),
                ),
              ),
          [],
        );
      });
    });

    group('From ModelB', () {
      isarTest('.aLinks()', () async {
        await qEqualSet(
          isar.modelBs.filter().aLinks((q) => q.nameStartsWith('a')),
          [b1, b2, b3, b4, b6],
        );

        await qEqualSet(
          isar.modelBs.filter().aLinks((q) => q.nameStartsWith('a 1')),
          [b1, b2, b3],
        );

        await qEqualSet(
          isar.modelBs.filter().aLinks((q) => q.nameStartsWith('a 2')),
          [b2, b3],
        );

        await qEqualSet(
          isar.modelBs.filter().aLinks((q) => q.nameStartsWith('a 3')),
          [b3, b4],
        );

        await qEqualSet(
          isar.modelBs.filter().aLinks((q) => q.nameStartsWith('a 4')),
          [b4],
        );

        await qEqualSet(
          isar.modelBs.filter().aLinks((q) => q.nameStartsWith('a 5')),
          [],
        );

        await qEqualSet(
          isar.modelBs.filter().aLinks((q) => q.nameStartsWith('a 6')),
          [b6],
        );

        await qEqualSet(
          isar.modelBs.filter().aLinks((q) => q.nameStartsWith('non existing')),
          [],
        );
      });

      isarTest('.aLinks() then .bLinks()', () async {
        await qEqualSet(
          isar.modelBs
              .filter()
              .aLinks((q) => q.bLinks((q) => q.nameStartsWith('b'))),
          [b1, b2, b3, b4],
        );

        await qEqualSet(
          isar.modelBs
              .filter()
              .aLinks((q) => q.bLinks((q) => q.nameEqualTo('b 1'))),
          [b1, b2, b3, b4],
        );

        await qEqualSet(
          isar.modelBs
              .filter()
              .aLinks((q) => q.bLinks((q) => q.nameEqualTo('b 2'))),
          [b2, b3, b4],
        );

        await qEqualSet(
          isar.modelBs
              .filter()
              .aLinks((q) => q.bLinks((q) => q.nameEqualTo('b 3'))),
          [b3, b4],
        );

        await qEqualSet(
          isar.modelBs
              .filter()
              .aLinks((q) => q.bLinks((q) => q.nameEqualTo('b 4'))),
          [b4],
        );

        await qEqualSet(
          isar.modelBs
              .filter()
              .aLinks((q) => q.bLinks((q) => q.nameEqualTo('b 5'))),
          [],
        );

        await qEqualSet(
          isar.modelBs
              .filter()
              .aLinks((q) => q.bLinks((q) => q.nameEqualTo('b 6'))),
          [],
        );

        await qEqualSet(
          isar.modelBs
              .filter()
              .aLinks((q) => q.bLinks((q) => q.nameEqualTo('non existing'))),
          [],
        );
      });

      isarTest('.aLinks() then .bLinks() then .aLinks()', () async {
        await qEqualSet(
          isar.modelBs.filter().aLinks(
                (q) => q.bLinks(
                  (q) => q.aLinks(
                    (q) => q.nameStartsWith('a'),
                  ),
                ),
              ),
          [b1, b2, b3, b4],
        );

        await qEqualSet(
          isar.modelBs.filter().aLinks(
                (q) => q.bLinks(
                  (q) => q.aLinks(
                    (q) => q.nameStartsWith('a 1'),
                  ),
                ),
              ),
          [b1, b2, b3, b4],
        );

        await qEqualSet(
          isar.modelBs.filter().aLinks(
                (q) => q.bLinks(
                  (q) => q.aLinks(
                    (q) => q.nameStartsWith('a 2'),
                  ),
                ),
              ),
          [b2, b3, b4],
        );

        await qEqualSet(
          isar.modelBs.filter().aLinks(
                (q) => q.bLinks(
                  (q) => q.aLinks(
                    (q) => q.nameStartsWith('a 3'),
                  ),
                ),
              ),
          [b3, b4],
        );

        await qEqualSet(
          isar.modelBs.filter().aLinks(
                (q) => q.bLinks(
                  (q) => q.aLinks(
                    (q) => q.nameStartsWith('a 4'),
                  ),
                ),
              ),
          [b4],
        );

        await qEqualSet(
          isar.modelBs.filter().aLinks(
                (q) => q.bLinks(
                  (q) => q.aLinks(
                    (q) => q.nameStartsWith('a 5'),
                  ),
                ),
              ),
          [],
        );

        await qEqualSet(
          isar.modelBs.filter().aLinks(
                (q) => q.bLinks(
                  (q) => q.aLinks(
                    (q) => q.nameStartsWith('a 6'),
                  ),
                ),
              ),
          [],
        );

        await qEqualSet(
          isar.modelBs.filter().aLinks(
                (q) => q.bLinks(
                  (q) => q.aLinks(
                    (q) => q.nameStartsWith('non existing'),
                  ),
                ),
              ),
          [],
        );
      });
    });
  });
}
