part of isar;

abstract class TypeConverter<T, I> {
  const TypeConverter();

  T fromIsar(I object);
  I toIsar(T object);
}
