part of isar;

/// @nodoc
@sealed
abstract class IsarLinkBase<OBJ> {
  /// Is the containing object managed by Isar?
  bool get isAttached;

  /// Have the contents been changed? If not, `.save()` is a no-op.
  bool get isChanged;

  /// Has this link been loaded?
  bool get isLoaded;

  /// {@template link_load}
  /// Loads the linked object(s) from the database
  /// {@endtemplate}
  Future<void> load();

  /// {@macro link_load}
  void loadSync();

  /// {@template link_save}
  /// Saves the linked object(s) to the database if there are changes.
  ///
  /// Also puts new objects into the database that have id set to `null` or
  /// `Isar.autoIncrement`.
  /// {@endtemplate}
  Future<void> save();

  /// {@macro link_save}
  void saveSync();

  /// {@template link_reset}
  /// Unlinks all linked object(s).
  ///
  /// You can even call this method on links that have not been loaded yet.
  /// {@endtemplate}
  Future<void> reset();

  /// {@macro link_reset}
  void resetSync();

  /// @nodoc
  @protected
  void attach(
    IsarCollection<dynamic> sourceCollection,
    IsarCollection<OBJ> targetCollection,
    String linkName,
    Id? objectId,
  );
}

mixin IsarLinkMixin<OBJ> implements IsarLink<OBJ> {
  // Burada metodlar ya soyut bırakılır ya da varsayılan implementasyonlar sağlanır.
}

/// Establishes a 1:1 relationship with the same or another collection. The
/// target collection is specified by the generic type argument.
abstract class IsarLink<OBJ> implements IsarLinkBase<OBJ> {
  /// Create an empty, unattached link. Make sure to provide the correct
  /// generic argument.
  factory IsarLink() => IsarLinkImpl();

  /// The linked object or `null` if no object is linked.
  OBJ? get value;

  /// The linked object or `null` if no object is linked.
  set value(OBJ? obj);
}

mixin IsarLinksMixin<OBJ> implements IsarLinks<OBJ> {
// Burada metodlar ya soyut bırakılır ya da varsayılan implementasyonlar sağlanır.
}

/// Establishes a 1:n relationship with the same or another collection. The
/// target collection is specified by the generic type argument.
abstract class IsarLinks<OBJ> implements IsarLinkBase<OBJ>, Set<OBJ> {
  /// Create an empty, unattached link. Make sure to provide the correct
  /// generic argument.
  factory IsarLinks() => IsarLinksImpl();

  @override
  Future<void> load({bool overrideChanges = true});

  @override
  void loadSync({bool overrideChanges = true});


  /// {@template links_update}
  /// Creates and removes the specified links in the database.
  ///
  /// This operation does not alter the state of the local copy of this link
  /// and it can even be used without loading the link.
  /// {@endtemplate}
  Future<void> update({
    Iterable<OBJ> link = const [],
    Iterable<OBJ> unlink = const [],
    bool reset = false,
  });

  /// {@macro links_update}
  void updateSync({
    Iterable<OBJ> link = const [],
    Iterable<OBJ> unlink = const [],
    bool reset = false,
  });

  /// Starts a query for linked objects.
  QueryBuilder<OBJ, OBJ, QAfterFilterCondition> filter();

  /// {@template links_count}
  /// Counts the linked objects in the database.
  ///
  /// It does not take the local state into account and can even be used
  /// without loading the link.
  /// {@endtemplate}
  Future<int> count() => filter().count();

  /// {@macro links_count}
  int countSync() => filter().countSync();
}
