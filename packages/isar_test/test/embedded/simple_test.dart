import 'package:test/test.dart';
import 'package:isar/isar.dart';

part 'simple_test.g.dart';

@Collection()
class Model {
  Model(this.id, this.embedded);

  final Id id;

  final EModel? embedded;
}

@Embedded()
class EModel {
  EModel([this.value = '']);

  final String value;
}

void main() {
  group('Embedded simple', () {});
}
