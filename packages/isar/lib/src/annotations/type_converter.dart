part of isar;

/// Extend `TypeConverter` to convert any type to a type supported by Isar.
///
/// It is your responsibility to make this class backwards compatible if
/// you change the schema of your collection.
abstract class TypeConverter<T, I> {
  const TypeConverter();

  /// Convert the value from the Isar type to the Dart type.
  T fromIsar(I object);

  /// Convert the value from the Dart type to the Isar type.
  I toIsar(T object);
}
