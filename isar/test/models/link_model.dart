import 'package:isar/isar.dart';

@Collection()
class LinkModel {
  int? id;

  late String name;

  var selfLink = IsarLink<LinkModel>();

  var otherLink = IsarLink<LinkModel2>();

  var selfLinks = IsarLinks<LinkModel>();

  var otherLinks = IsarLinks<LinkModel2>();

  @Backlink(to: 'selfLink')
  var selfLinkBacklink = IsarLinks<LinkModel>();

  @Backlink(to: 'selfLinks')
  var selfLinksBacklink = IsarLinks<LinkModel>();

  LinkModel();

  LinkModel.name(this.name);

  @override
  String toString() {
    return 'LinkModel($name)';
  }

  @override
  operator ==(Object other) {
    return other is LinkModel && other.name == name;
  }
}

@Collection()
class LinkModel2 {
  int? id;

  late String name;

  @Backlink(to: 'otherLink')
  var linkBacklinks = IsarLinks<LinkModel>();

  @Backlink(to: 'otherLinks')
  var linksBacklinks = IsarLinks<LinkModel>();

  LinkModel2();

  LinkModel2.name(this.name);

  @override
  String toString() {
    return 'LinkModel2($name)';
  }

  @override
  operator ==(Object other) {
    return other is LinkModel2 && other.name == name;
  }
}
