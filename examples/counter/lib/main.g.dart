// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// _IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, invalid_use_of_protected_member, lines_longer_than_80_chars, constant_identifier_names, avoid_js_rounded_ints, no_leading_underscores_for_local_identifiers, require_trailing_commas, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_in_if_null_operators, library_private_types_in_public_api, prefer_const_constructors
// ignore_for_file: type=lint

extension GetCountCollection on Isar {
  IsarCollection<int, Count> get counts => this.collection();
}

const CountSchema = IsarGeneratedSchema(
  schema: IsarSchema(
    name: "Count",
    idName: "id",
    embedded: false,
    properties: [
      IsarPropertySchema(
        name: "step",
        type: IsarType.long,
      ),
    ],
    indexes: [],
  ),
  converter: IsarObjectConverter<int, Count>(
    serialize: serializeCount,
    deserialize: deserializeCount,
    deserializeProperty: deserializeCountProp,
  ),
  embeddedSchemas: [],
);

@isarProtected
int serializeCount(IsarWriter writer, Count object) {
  IsarCore.writeLong(writer, 1, object.step);
  return object.id;
}

@isarProtected
Count deserializeCount(IsarReader reader) {
  final int _id;
  _id = IsarCore.readId(reader);
  final int _step;
  _step = IsarCore.readLong(reader, 1);
  final object = Count(
    _id,
    _step,
  );
  return object;
}

@isarProtected
dynamic deserializeCountProp(IsarReader reader, int property) {
  switch (property) {
    case 0:
      return IsarCore.readId(reader);
    case 1:
      return IsarCore.readLong(reader, 1);
    default:
      throw ArgumentError('Unknown property: $property');
  }
}

sealed class _CountUpdate {
  bool call({
    required int id,
    int? step,
  });
}

class _CountUpdateImpl implements _CountUpdate {
  const _CountUpdateImpl(this.collection);

  final IsarCollection<int, Count> collection;

  @override
  bool call({
    required int id,
    Object? step = ignore,
  }) {
    return collection.updateProperties([
          id
        ], {
          if (step != ignore) 1: step as int?,
        }) >
        0;
  }
}

sealed class _CountUpdateAll {
  int call({
    required List<int> id,
    int? step,
  });
}

class _CountUpdateAllImpl implements _CountUpdateAll {
  const _CountUpdateAllImpl(this.collection);

  final IsarCollection<int, Count> collection;

  @override
  int call({
    required List<int> id,
    Object? step = ignore,
  }) {
    return collection.updateProperties(id, {
      if (step != ignore) 1: step as int?,
    });
  }
}

extension CountUpdate on IsarCollection<int, Count> {
  _CountUpdate get update => _CountUpdateImpl(this);

  _CountUpdateAll get updateAll => _CountUpdateAllImpl(this);
}

sealed class _CountQueryUpdate {
  int call({
    int? step,
  });
}

class _CountQueryUpdateImpl implements _CountQueryUpdate {
  const _CountQueryUpdateImpl(this.query, {this.limit});

  final IsarQuery<Count> query;
  final int? limit;

  @override
  int call({
    Object? step = ignore,
  }) {
    return query.updateProperties(limit: limit, {
      if (step != ignore) 1: step as int?,
    });
  }
}

extension CountQueryUpdate on IsarQuery<Count> {
  _CountQueryUpdate get updateFirst => _CountQueryUpdateImpl(this, limit: 1);

  _CountQueryUpdate get updateAll => _CountQueryUpdateImpl(this);
}

class _CountQueryBuilderUpdateImpl implements _CountQueryUpdate {
  const _CountQueryBuilderUpdateImpl(this.query, {this.limit});

  final QueryBuilder<Count, Count, QOperations> query;
  final int? limit;

  @override
  int call({
    Object? step = ignore,
  }) {
    final q = query.build();
    try {
      return q.updateProperties(limit: limit, {
        if (step != ignore) 1: step as int?,
      });
    } finally {
      q.close();
    }
  }
}

extension CountQueryBuilderUpdate on QueryBuilder<Count, Count, QOperations> {
  _CountQueryUpdate get updateFirst =>
      _CountQueryBuilderUpdateImpl(this, limit: 1);

  _CountQueryUpdate get updateAll => _CountQueryBuilderUpdateImpl(this);
}

extension CountQueryFilter on QueryBuilder<Count, Count, QFilterCondition> {
  QueryBuilder<Count, Count, QAfterFilterCondition> idEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Count, Count, QAfterFilterCondition> idGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Count, Count, QAfterFilterCondition> idGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Count, Count, QAfterFilterCondition> idLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Count, Count, QAfterFilterCondition> idLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 0,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Count, Count, QAfterFilterCondition> idBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 0,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }

  QueryBuilder<Count, Count, QAfterFilterCondition> stepEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        EqualCondition(
          property: 1,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Count, Count, QAfterFilterCondition> stepGreaterThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterCondition(
          property: 1,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Count, Count, QAfterFilterCondition> stepGreaterThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        GreaterOrEqualCondition(
          property: 1,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Count, Count, QAfterFilterCondition> stepLessThan(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessCondition(
          property: 1,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Count, Count, QAfterFilterCondition> stepLessThanOrEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        LessOrEqualCondition(
          property: 1,
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Count, Count, QAfterFilterCondition> stepBetween(
    int lower,
    int upper,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        BetweenCondition(
          property: 1,
          lower: lower,
          upper: upper,
        ),
      );
    });
  }
}

extension CountQueryObject on QueryBuilder<Count, Count, QFilterCondition> {}

extension CountQuerySortBy on QueryBuilder<Count, Count, QSortBy> {
  QueryBuilder<Count, Count, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<Count, Count, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<Count, Count, QAfterSortBy> sortByStep() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1);
    });
  }

  QueryBuilder<Count, Count, QAfterSortBy> sortByStepDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc);
    });
  }
}

extension CountQuerySortThenBy on QueryBuilder<Count, Count, QSortThenBy> {
  QueryBuilder<Count, Count, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0);
    });
  }

  QueryBuilder<Count, Count, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(0, sort: Sort.desc);
    });
  }

  QueryBuilder<Count, Count, QAfterSortBy> thenByStep() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1);
    });
  }

  QueryBuilder<Count, Count, QAfterSortBy> thenByStepDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(1, sort: Sort.desc);
    });
  }
}

extension CountQueryWhereDistinct on QueryBuilder<Count, Count, QDistinct> {
  QueryBuilder<Count, Count, QAfterDistinct> distinctByStep() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(1);
    });
  }
}

extension CountQueryProperty1 on QueryBuilder<Count, Count, QProperty> {
  QueryBuilder<Count, int, QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<Count, int, QAfterProperty> stepProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }
}

extension CountQueryProperty2<R> on QueryBuilder<Count, R, QAfterProperty> {
  QueryBuilder<Count, (R, int), QAfterProperty> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<Count, (R, int), QAfterProperty> stepProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }
}

extension CountQueryProperty3<R1, R2>
    on QueryBuilder<Count, (R1, R2), QAfterProperty> {
  QueryBuilder<Count, (R1, R2, int), QOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(0);
    });
  }

  QueryBuilder<Count, (R1, R2, int), QOperations> stepProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addProperty(1);
    });
  }
}
