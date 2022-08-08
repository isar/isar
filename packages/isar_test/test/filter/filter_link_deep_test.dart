import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';

part 'filter_link_deep_test.g.dart';

@Collection()
class LinkDeepModelA {
  LinkDeepModelA(this.name);

  Id? id;

  late String name;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    return other is LinkDeepModelA && id == other.id && other.name == name;
  }
}

@Collection()
class LinkDeepModelB {
  LinkDeepModelB(this.name);

  Id? id;
  late String name;
  final linkDeepModela = IsarLink<LinkDeepModelA>();

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    return other is LinkDeepModelB && id == other.id && other.name == name;
  }
}

@Collection()
class LinkDeepModelC {
  LinkDeepModelC(this.name);

  Id? id;
  late String name;
  final linkDeepModelb = IsarLink<LinkDeepModelB>();

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    return other is LinkDeepModelC && id == other.id && other.name == name;
  }
}

void main() {
  group('Groups', () {
    late Isar isar;
    late IsarCollection<LinkDeepModelA> colA;
    late IsarCollection<LinkDeepModelB> colB;
    late IsarCollection<LinkDeepModelC> colC;

    late LinkDeepModelA objA1;
    late LinkDeepModelA objA2;
    late LinkDeepModelB objB1;
    late LinkDeepModelB objB2;
    late LinkDeepModelC objC1;
    late LinkDeepModelC objC2;

    setUp(() async {
      isar = await openTempIsar(
          [LinkDeepModelASchema, LinkDeepModelBSchema, LinkDeepModelCSchema]);
      colA = isar.linkDeepModelAs;
      colB = isar.linkDeepModelBs;
      colC = isar.linkDeepModelCs;

      objA1 = LinkDeepModelA('model a1');
      objA2 = LinkDeepModelA('model a2');

      objB1 = LinkDeepModelB('model b1')..linkDeepModela.value = objA1;
      objB2 = LinkDeepModelB('model b2')..linkDeepModela.value = objA2;

      objC1 = LinkDeepModelC('model c1')..linkDeepModelb.value = objB1;
      objC2 = LinkDeepModelC('model c2')..linkDeepModelb.value = objB2;
      ;

      isar.writeTxnSync(() {
        colA.putSync(objA1, saveLinks: true);
        colA.putSync(objA2, saveLinks: true);

        objB1.linkDeepModela.value = objA1;
        objB2.linkDeepModela.value = objA2;
        colB.putSync(objB1, saveLinks: true);
        colB.putSync(objB2, saveLinks: true);

        objC1.linkDeepModelb.value = objB1;
        objC2.linkDeepModelb.value = objB2;
        colC.putSync(objC1, saveLinks: true);
        colC.putSync(objC2, saveLinks: true);
      });
    });

    tearDown(() => isar.close(deleteFromDisk: true));

    isarTest('.equalTo()', () async {
      // filters

      await qEqual(
          colC
              .filter()
              .linkDeepModelb(
                  (q) => q.linkDeepModela((q) => q.nameEqualTo('model a1')))
              .findAll(),
          [objC1]);
    });
  });
}
