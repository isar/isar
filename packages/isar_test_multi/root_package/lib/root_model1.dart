import 'package:isar/isar.dart';

@Collection()
class RootModel1 {
  int? id;

  String? name;

  @override
  operator ==(other) {
    if (other is RootModel1) {
      return name == other.name;
    } else {
      return false;
    }
  }
}
