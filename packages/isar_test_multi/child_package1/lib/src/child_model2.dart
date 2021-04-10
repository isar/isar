import 'package:isar/isar.dart';

@Collection()
class ChildModel2 {
  int? id;

  String? name;

  @override
  operator ==(other) {
    if (other is ChildModel2) {
      return name == other.name;
    } else {
      return false;
    }
  }
}
