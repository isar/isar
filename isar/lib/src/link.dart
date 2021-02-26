import 'dart:core';

class Link<OBJ> {
  Links<OBJ> _links;

  Future<OBJ?> get() => _links.getAt(0);

  OBJ? getSync() => _links.getAtSync(0);

  Future<void> set(OBJ? object) => _links.setAt(0, object);

  void setSync(OBJ? object) => _links.setAtSync(0, object);
}

abstract class Links<OBJ> {
  Future<OBJ?> getAt(int index);

  OBJ? getAtSync(int index);

  Future<void> setAt(int index, OBJ? object);

  void setAtSync(int index, OBJ? object);

  Future<List<OBJ>> getAll();

  List<OBJ> getAllSync();

  Future<void> setAll(List<OBJ> objects);

  void setAllSync(List<OBJ> objects);
}
