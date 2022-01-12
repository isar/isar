part of isar;

abstract class IsarLinkBase<OBJ> {
  bool get isAttached;
  bool get isChanged;

  Future<void> load();

  void loadSync();

  Future<void> save();

  void saveSync();

  void attach(IsarCollection col, IsarCollection<OBJ> targetCol,
      dynamic containingObject, String linkName, bool backlink);
}

abstract class IsarLink<OBJ> extends IsarLinkBase<OBJ> {
  factory IsarLink() {
    if (kIsWeb) {
      throw UnimplementedError();
    } else {
      return nativeIsarLink();
    }
  }

  OBJ? get value;

  set value(OBJ? obj);
}

abstract class IsarLinks<OBJ> extends IsarLinkBase<OBJ> implements Set<OBJ> {
  factory IsarLinks() {
    if (kIsWeb) {
      throw UnimplementedError();
    } else {}
    return nativeIsarLinks();
  }

  @override
  Future<void> load({bool overrideChanges = false});

  @override
  void loadSync({bool overrideChanges = false});
}
