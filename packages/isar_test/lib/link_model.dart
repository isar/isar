import 'package:isar/isar.dart';

part 'link_model.g.dart';

@Collection()
class LinkModelA {
  int? id;

  late String name;

  final selfLink = IsarLink<LinkModelA>();

  final otherLink = IsarLink<LinkModelB>();

  var selfLinks = IsarLinks<LinkModelA>();

  final otherLinks = IsarLinks<LinkModelB>();

  @Backlink(to: 'selfLink')
  final selfLinkBacklink = IsarLinks<LinkModelA>();

  @Backlink(to: 'selfLinks')
  final selfLinksBacklink = IsarLinks<LinkModelA>();

  LinkModelA();

  LinkModelA.name(this.name);

  @override
  String toString() {
    return 'LinkModelA($id, $name)';
  }

  @override
  bool operator ==(Object other) {
    return other is LinkModelA && id == other.id && other.name == name;
  }
}

@Collection()
class LinkModelB {
  int? id;

  late String name;

  @Backlink(to: 'otherLink')
  final linkBacklinks = IsarLinks<LinkModelA>();

  @Backlink(to: 'otherLinks')
  var linksBacklinks = IsarLinks<LinkModelA>();

  LinkModelB();

  LinkModelB.name(this.name);

  @override
  String toString() {
    return 'LinkModelB($id, $name)';
  }

  @override
  bool operator ==(Object other) {
    return other is LinkModelB && id == other.id && other.name == name;
  }
}
