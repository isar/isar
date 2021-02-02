part of isar_native;

abstract class TypeAdapter<T> {
  void serialize(RawObject rawObj, T object, List<int> offsets);

  T deserialize(BinaryReader reader, List<int> offsets);
}
