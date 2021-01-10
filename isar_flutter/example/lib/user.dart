import 'package:isar/isar.dart';

@Collection()
class User with IsarObject {
  @Index(composite: ['age'], hashValue: true, unique: false)
  late String name;

  @Index(unique: false)
  late int age;

  @override
  String toString() {
    return "name: $name  age: $age";
  }
}
