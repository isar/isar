import 'package:isar/isar.dart';

part 'name_model.g.dart';

@Collection()
@Name('NameModelN')
class NameModel {
  @Id()
  @Name('idN')
  int? id;

  @Index()
  @Name('valueN')
  String? value;

  @Index(composite: [CompositeIndex('value')])
  @Name('otherValueN')
  String? otherValue;

  @Name('linkN')
  var link = IsarLinks<NameModel>();

  @Backlink(to: 'linkN')
  @Name('backlink')
  var backlink = IsarLinks<NameModel>();
}
