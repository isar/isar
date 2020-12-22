import 'package:isar/internal_native.dart';

abstract class TypeAdapter<T> {
  int get staticSize;

  int prepareSerialize(T object, Map<String, dynamic> cache);

  void serialize(T object, Map<String, dynamic> cache, BinaryWriter writer);

  T deserialize(BinaryReader reader);
}
