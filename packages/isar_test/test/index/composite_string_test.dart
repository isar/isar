import 'package:isar/isar.dart';
import 'package:test/test.dart';

part 'composite_string_test.g.dart';

@Collection()
class Model {
  int? id;

  @Index(
    composite: [
      CompositeIndex(
        'value2',
        type: IndexType.value,
      )
    ],
    unique: true,
  )
  String value;

  String value2;

  Model(this.value, this.value2);

  @override
  String toString() {
    return '{id: $id, value: $value, value2: $value2}';
  }

  @override
  bool operator ==(other) {
    return (other is Model) &&
        other.id == id &&
        other.value == value &&
        other.value2 == value2;
  }
}

void main() {
  group('CRUD', () {});
}
