import 'package:isar/isar.dart';

@Collection()
class ChildModel3 {
  int? id;

  String? name;

  @override
  operator ==(other) {
    if (other is ChildModel3) {
      return name == other.name;
    } else {
      return false;
    }
  }
}

@Collection()
class ChildModel4 {
  int? id;

  String? name;

  @override
  operator ==(other) {
    if (other is ChildModel4) {
      return name == other.name;
    } else {
      return false;
    }
  }
}
