part of isar_annotation;

abstract class Converter<T, I> {
  const Converter();

  T fromIsar(I object);
  I toIsar(T object);
}
