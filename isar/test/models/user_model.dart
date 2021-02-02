import 'package:isar/isar.dart';
import 'package:isar_annotation/isar_annotation.dart';

@Collection()
class UserModel {
  @ObjectId()
  late String name;

  late int age;

  List<String?>? friends;

  @override
  bool operator ==(Object other) {
    if (other is UserModel) {
      if (friends != null) {
        if (other.friends == null) return false;
        for (var i = 0; i < friends!.length; i++) {
          if (friends![i] != other.friends![i]) return false;
        }
      }
      return name == other.name && age == other.age;
    } else {
      return false;
    }
  }
}
