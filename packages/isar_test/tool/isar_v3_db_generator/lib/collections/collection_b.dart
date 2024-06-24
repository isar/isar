import 'package:isar/isar.dart';

part 'collection_b.g.dart';

@collection
class CollectionB {
  Id id;

  @Index()
  int duplicatedId;

  String? fieldA;

  EmbeddedA embeddedA;
  EmbeddedA? nEmbeddedA;
  List<EmbeddedA> embeddedAList;
  List<EmbeddedA>? embeddedANList;
  List<EmbeddedA?> nEmbeddedAList;
  List<EmbeddedA?>? nEmbeddedANList;

  final link = IsarLink<CollectionB>();

  CollectionB({
    required this.id,
    required this.duplicatedId,
    required this.fieldA,
    required this.embeddedA,
    required this.nEmbeddedA,
    required this.embeddedAList,
    required this.embeddedANList,
    required this.nEmbeddedAList,
    required this.nEmbeddedANList,
  });
}

@embedded
class EmbeddedA {
  String? fieldA;
  bool? fieldB;

  EmbeddedA? embeddedA;
  EmbeddedB? embeddedB;
  List<EmbeddedB>? embeddedBNList;
  List<EmbeddedB?>? nEmbeddedBNList;

  EmbeddedA({
    this.fieldA,
    this.fieldB,
    this.embeddedA,
    this.embeddedB,
    this.embeddedBNList,
    this.nEmbeddedBNList,
  });
}

@embedded
class EmbeddedB {
  String? fieldA;
  int? fieldC;

  EmbeddedB({
    this.fieldA,
    this.fieldC,
  });
}
