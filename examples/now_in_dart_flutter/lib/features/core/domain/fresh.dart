import 'package:equatable/equatable.dart';

class Fresh<T> extends Equatable {
  const Fresh._({this.entity, this.isFresh});

  /// Factory for [WhenFresh]
  const factory Fresh.yes({
    required T entity,
  }) = WhenFresh<T>._;

  /// Factory for [WhenNotFresh]
  const factory Fresh.no({
    required T entity,
  }) = WhenNotFresh<T>._;

  /// Entity whose freshness is to be checked.
  final T? entity;

  /// Determines if the entity is fresh or not.
  final bool? isFresh;

  @override
  List<Object?> get props => [entity, isFresh];
}

/// Represents that the entity is fresh.
class WhenFresh<T> extends Fresh<T> {
  const WhenFresh._({
    required T super.entity,
  }) : super._(isFresh: true);

  @override
  String toString() {
    return 'WhenFresh(entity: $entity, isFresh: true)';
  }
}

/// Represents that the entity is not fresh.
class WhenNotFresh<T> extends Fresh<T> {
  const WhenNotFresh._({
    required T super.entity,
  }) : super._(isFresh: false);

  @override
  String toString() {
    return 'WhenNotFresh(entity: $entity, isFresh: false)';
  }
}
