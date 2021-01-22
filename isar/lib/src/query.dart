part of isar;

abstract class Query<T> {
  Future<T?> findFirst() async {
    /*final results = await findAll(limit: 1);
    if (results.isNotEmpty) {
      return results.first;
    } else {
      return null;
    }*/
    throw UnimplementedError();
  }

  T? findFirstSync() {
    /*final results = findAllSync(limit: 1);
    if (results.isNotEmpty) {
      return results.first;
    } else {
      return null;
    }*/
    throw UnimplementedError();
  }

  Future<List<T>> findAll();

  List<T> findAllSync();

  Future<int> count();

  int countSync();

  Future<bool> deleteFirst();

  bool deleteFirstSync();

  Future<int> deleteAll();

  int deleteAllSync();

  Stream<void> watchChanges();

  Stream<List<T>> watch();
}
