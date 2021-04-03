part of isar_native;

abstract class TypeAdapter<T> {
  int serialize(IsarCollectionImpl<T> collection, RawObject rawObj, T object,
      List<int> offsets,
      [int? existingBufferSize]);

  T deserialize(
      IsarCollectionImpl<T> collection, BinaryReader reader, List<int> offsets);

  P deserializeProperty<P>(BinaryReader reader, int propertyIndex, int offset);
}
