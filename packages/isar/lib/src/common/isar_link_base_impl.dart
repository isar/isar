import 'package:isar/isar.dart';

/// @nodoc
abstract class IsarLinkBaseImpl<OBJ> implements IsarLinkBase<OBJ> {
  var _initialized = false;

  Id? _objectId;

  /// The isar name of the link
  late final String linkName;

  /// The origin collection of the link. For backlinks it is actually the target
  /// collection.
  late final IsarCollection<dynamic> sourceCollection;

  /// The target collection of the link. For backlinks it is actually the origin
  /// collection.
  late final IsarCollection<OBJ> targetCollection;

  @override
  bool get isAttached => _objectId != null;

  @override
  void attach(
    IsarCollection<dynamic> sourceCollection,
    IsarCollection<OBJ> targetCollection,
    String linkName,
    Id? objectId,
  ) {
    if (_initialized) {
      if (linkName != this.linkName ||
          !identical(sourceCollection, this.sourceCollection) ||
          !identical(targetCollection, this.targetCollection)) {
        throw IsarError(
          'Link has been moved! It is not allowed to move '
          'a link to a different collection.',
        );
      }
    } else {
      _initialized = true;
      this.sourceCollection = sourceCollection;
      this.targetCollection = targetCollection;
      this.linkName = linkName;
    }

    _objectId = objectId;
  }

  /// Returns the containing object's id or throws an exception if this link has
  /// not been attached to an object yet.
  Id requireAttached() {
    if (_objectId == null) {
      throw IsarError(
        'Containing object needs to be managed by Isar to use this method. '
        'Use collection.put(yourObject) to add it to the database.',
      );
    } else {
      return _objectId!;
    }
  }

  /// Returns the id of a linked object.
  Id Function(OBJ obj) get getId;

  /// Returns the id of a linked object or throws an exception if the id is
  /// `null` or set to `Isar.autoIncrement`.
  Id requireGetId(OBJ object) {
    final id = getId(object);
    if (id != Isar.autoIncrement) {
      return id;
    } else {
      throw IsarError(
        'Object "$object" has no id and can therefore not be linked. '
        'Make sure to .put() objects before you use them in links.',
      );
    }
  }

  /// See [IsarLinks.filter].
  QueryBuilder<OBJ, OBJ, QAfterFilterCondition> filter() {
    final containingId = requireAttached();
    final qb = QueryBuilderInternal(
      collection: targetCollection,
      whereClauses: [
        LinkWhereClause(
          linkCollection: sourceCollection.name,
          linkName: linkName,
          id: containingId,
        ),
      ],
    );
    return QueryBuilder(qb);
  }

  /// See [IsarLinks.update].
  Future<void> update({
    Iterable<OBJ> link = const [],
    Iterable<OBJ> unlink = const [],
    bool reset = false,
  });

  /// See [IsarLinks.updateSync].
  void updateSync({
    Iterable<OBJ> link = const [],
    Iterable<OBJ> unlink = const [],
    bool reset = false,
  });
}
