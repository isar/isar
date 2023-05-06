part of isar;

class _QueryImpl<T> implements Query<T> {
  _QueryImpl(this.isar, this.ptr, this.deserialize);

  final _IsarImpl isar;
  final Pointer<CIsarQuery> ptr;
  final Deserialize<T> deserialize;

  @override
  T? findFirst() {
    return isar.txn((isar) {});
  }

  @override
  List<T> findAll() {
    // TODO: implement findAll
    throw UnimplementedError();
  }

  @override
  bool deleteFirst() {
    // TODO: implement deleteFirst
    throw UnimplementedError();
  }

  @override
  int deleteAll() {
    // TODO: implement deleteAll
    throw UnimplementedError();
  }
}
