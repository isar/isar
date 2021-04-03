class Test<T> {
  final T Function(T) test;

  Test(this.test);
}

void main() {
  final t = Test((int a) => a * 2);
  Test t2 = t;
  exec(t2, 4);
}

void exec<T>(Test r, T t) {
  print((r as Test<T>).test(t));
}
