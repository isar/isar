part of isar;

abstract class IsarLink<OBJ> {
  factory IsarLink() {
    return newIsarLink();
  }

  OBJ? get value;

  set value(OBJ? obj);

  bool get isChanged;

  Future<void> load();

  void loadSync();

  Future<void> save();

  void saveSync();
}

abstract class IsarLinks<OBJ> implements Set<OBJ> {
  factory IsarLinks() {
    return newIsarLinks();
  }

  bool get hasChanges;

  Future<void> load({bool overrideChanges = false});

  void loadSync({bool overrideChanges = false});

  Future<void> saveChanges();

  void saveChangesSync();
}
