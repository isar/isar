import 'package:isar/isar.dart';

@Collection()
class LinkModelA {
  int? id;

  late String name;

  var selfLink = IsarLink<LinkModelA>();

  var otherLink = IsarLink<LinkModelB>();

  var selfLinks = IsarLinks<LinkModelA>();

  var otherLinks = IsarLinks<LinkModelB>();

  @Backlink(to: 'selfLink')
  var selfLinkBacklink = IsarLinks<LinkModelA>();

  @Backlink(to: 'selfLinks')
  var selfLinksBacklink = IsarLinks<LinkModelA>();

  LinkModelA();

  LinkModelA.name(this.name);

  @override
  String toString() {
    return 'LinkModelA($name)';
  }

  @override
  operator ==(Object other) {
    return other is LinkModelA && other.name == name;
  }
}

@Collection()
class LinkModelB {
  int? id;

  late String name;

  @Backlink(to: 'otherLink')
  var linkBacklinks = IsarLinks<LinkModelA>();

  @Backlink(to: 'otherLinks')
  var linksBacklinks = IsarLinks<LinkModelA>();

  LinkModelB();

  LinkModelB.name(this.name);

  @override
  String toString() {
    return 'LinkModelB($name)';
  }

  @override
  operator ==(Object other) {
    return other is LinkModelB && other.name == name;
  }
}
