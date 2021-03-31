part of isar;

abstract class Query<T> {
  Future<T?> findFirst();

  T? findFirstSync();

  Future<List<T>> findAll();

  List<T> findAllSync();

  Future<int> count();

  int countSync();

  Future<bool> deleteFirst();

  bool deleteFirstSync();

  Future<int> deleteAll();

  int deleteAllSync();

  Stream<List<T>> watch({bool initialReturn = false});

  Stream<void> watchLazy();
}
