import 'package:isar/isar.dart';

part 'user_model.g.dart';

@collection
class UserModel {
  UserModel();

  UserModel.fill(this.name, this.age, this.admin);
  Id? id;

  @Index()
  String? name;

  @Index()
  int? age = 0;

  bool admin = false;

  @override
  String toString() {
    return '{name: $name, age: $age, admin: $admin}';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    // ignore: test_types_in_equals
    return other is UserModel &&
        name == other.name &&
        age == other.age &&
        admin == other.admin;
  }
}
