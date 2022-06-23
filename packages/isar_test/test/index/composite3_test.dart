import 'package:isar/isar.dart';
import 'package:test/test.dart';

part 'composite3_test.g.dart';

@Collection()
class Model {
  int? id;

  @Index(
    composite: [
      CompositeIndex('value2'),
      CompositeIndex('value3'),
    ],
    unique: true,
  )
  int value1;

  int value2;

  int value3;

  Model(this.value1, this.value2, this.value3);

  @override
  String toString() {
    return '{id: $id, value1: $value1, value2: $value2, value3: $value3}';
  }

  @override
  bool operator ==(other) {
    return (other is Model) &&
        other.id == id &&
        other.value1 == value1 &&
        other.value2 == value2 &&
        value3 == value3;
  }
}

void main() {
  group('CRUD', () {});
}
