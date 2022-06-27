// Converters are not allowed for ids

import 'package:isar/isar.dart';

@Collection()
class Test {
  @Id()
  @Converter()
  late String id;
}

class Converter extends TypeConverter<String, int> {
  const Converter();

  @override
  String fromIsar(int object) {
    return object.toString();
  }

  @override
  int toIsar(String object) {
    return int.parse(object);
  }
}
