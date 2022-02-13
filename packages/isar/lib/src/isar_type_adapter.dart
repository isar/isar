part of isar;

/// @nodoc
@protected
typedef AdapterAlloc = IsarBytePointer Function(int size);

/// @nodoc
@protected
abstract class IsarNativeTypeAdapter<T> {
  const IsarNativeTypeAdapter();

  void serialize(IsarCollection<T> collection, IsarRawObject rawObj, T object,
      int staticSize, List<int> offsets, AdapterAlloc alloc);

  T deserialize(IsarCollection<T> collection, int id, IsarBinaryReader reader,
      List<int> offsets);

  P deserializeProperty<P>(
      int id, IsarBinaryReader reader, int propertyIndex, int offset);
}

/// @nodoc
@protected
abstract class IsarWebTypeAdapter<T> {
  const IsarWebTypeAdapter();

  dynamic serialize(IsarCollection<T> collection, T object);

  T deserialize(IsarCollection<T> collection, dynamic jsObj);

  P deserializeProperty<P>(Object jsObj, String propertyName);
}
