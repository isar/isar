part of isar;

/// @nodoc
@protected
abstract class IsarLinkBase<OBJ> {
  /// Is the containing object managed by Isar?
  bool get isAttached;

  /// Have the contents been changed? If not, `.save()` is a no-op.
  bool get isChanged;

  /// Loads the linked object(s) from the databse
  Future<void> load();

  /// Loads the linked object(s) from the databse
  void loadSync();

  /// Saves the linked object(s) to the databse if there are changes.
  ///
  /// Also puts new objects into the database that have id set to `null` or
  /// `Isar.autoIncrement`.
  Future<void> save();

  /// Saves the linked object(s) to the databse if there are changes.
  ///
  /// Also puts new objects into the database that have id set to `null` or
  /// `Isar.autoIncrement`.
  void saveSync();

  /// Unlinks all linked object(s).
  ///
  /// You can even call this method on links that have not been loaded yet.
  Future<void> reset();

  /// Unlinks all linked object(s).
  ///
  /// You can even call this method on links that have not been loaded yet.
  void resetSync();

  /// @nodoc
  @protected
  void attach(int? objectId, IsarCollection col, IsarCollection<OBJ> targetCol,
      String linkName, bool backlink);
}

/// Establishes a 1:1 relationship with the same or another collection. The
/// target collection is specified by the generic type argument.
abstract class IsarLink<OBJ> extends IsarLinkBase<OBJ> {
  /// Create an empty, unattached link. Make sure to provide the correct
  /// generic argument.
  factory IsarLink() => IsarNative.newLink();

  /// The linked object or `null` if no object is linked.
  OBJ? get value;

  /// The linked object or `null` if no object is linked.
  set value(OBJ? obj);
}

/// Establishes a 1:n relationship with the same or another collection. The
/// target collection is specified by the generic type argument.
abstract class IsarLinks<OBJ> extends IsarLinkBase<OBJ> implements Set<OBJ> {
  /// Create an empty, unattached link. Make sure to provide the correct
  /// generic argument.
  factory IsarLinks() => IsarNative.newLinks();

  @override
  Future<void> load({bool overrideChanges = true});

  @override
  void loadSync({bool overrideChanges = true});
}
