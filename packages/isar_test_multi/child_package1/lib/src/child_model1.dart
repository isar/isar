import 'package:isar/isar.dart';

@Collection()
class ChildModel1 {
  int? id;

  String? name;

  @override
  operator ==(other) {
    if (other is ChildModel1) {
      return name == other.name;
    } else {
      return false;
    }
  }
}
