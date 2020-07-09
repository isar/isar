import 'package:isar/src/native/bindings/structs.dart';

abstract class TypeAdapter<T> {
  void serialize(T object, RawObject rawObject);

  T deserialize(RawObject rawObject);
}
