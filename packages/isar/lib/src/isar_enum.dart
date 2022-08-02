mixin IsarEnum<T> on Enum {
  T get isarValue;
}

enum TX with IsarEnum<int> {
  a;

  int get isarValue => 5;
}
