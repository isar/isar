import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:isar/isar.dart';
import 'package:isar/src/impl/bindings.dart';
import 'package:isar/src/impl/filter_builder.dart';
import 'package:isar/src/impl/isar_core.dart';
import 'package:isar/src/impl/isar_impl.dart';

class IsarCollectionImpl<T> implements IsarCollection<T> {
  final IsarImpl isar;

  final int collectionIndex;

  final CollectionSchema<T> schema;

  @override
  T? get(int id) {}

  @override
  void clear() {
    // TODO: implement clear
  }

  @override
  int count() {
    // TODO: implement count
    throw UnimplementedError();
  }

  @override
  bool delete(int id) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  int put(T object) {
    // TODO: implement put
    throw UnimplementedError();
  }

  @override
  QueryBuilder<T, T, QFilter> where() {
    // TODO: implement where
    throw UnimplementedError();
  }

  Query<R> buildQuery<R>({
    Filter? filter,
    List<SortProperty> sortBy = const [],
    List<DistinctProperty> distinctBy = const [],
    int? offset,
    int? limit,
    String? property,
  }) {
    final alloc = Arena(malloc);
    final builderPtrPtr = alloc<Pointer<CIsarQueryBuilder>>();
    IC.isar_build_query(isar.ptr, builderPtrPtr, collectionIndex);

    final builderPtr = builderPtrPtr.value;
    if (filter != null) {
      final filterPtr = buildFilter(alloc, filter);
      IC.isar_query_builder_set_filter(builderPtr, filterPtr);
    }

    for (final sort in sortBy) {
      IC.isar_query_builder_add_sort(
        builderPtr,
        sort.property,
        sort.sort == Sort.asc,
      );
    }
  }
}
