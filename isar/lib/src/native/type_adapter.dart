part of isar_native;

abstract class TypeAdapter<T> {
  int serialize(RawObject rawObj, T object, List<int> offsets,
      [int? existingBufferSize]);

  T deserialize(BinaryReader reader, List<int> offsets);
}
