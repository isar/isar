import 'package:isar/isar.dart';

@Collection()
class RootModel2 {
  int? id;

  String? name;

  @override
  operator ==(other) {
    if (other is RootModel2) {
      return name == other.name;
    } else {
      return false;
    }
  }
}
