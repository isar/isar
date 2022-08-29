import 'package:isar/isar.dart';
import 'package:isar/src/common/isar_link_base_impl.dart';

const bool _kIsWeb = identical(0, 0.0);

/// @nodoc
abstract class IsarLinkCommon<OBJ> extends IsarLinkBaseImpl<OBJ>
    with IsarLink<OBJ> {
  OBJ? _value;

  int? _valueId;

  @override
  bool isChanged = false;

  @override
  bool isLoaded = false;

  @override
  bool isIdLoaded = false;

  @override
  OBJ? get value {
    if (isAttached && !isLoaded && !_kIsWeb) {
      loadSync();
    }
    return _value;
  }

  @override
  set value(OBJ? value) {
    isChanged |= !identical(_value, value);
    _value = value;
    isLoaded = true;
    _valueId = _value == null ? null : getId(_value!);
    isIdLoaded = true;
  }

  @override
  int? get valueId {
    if (isAttached && !isIdLoaded && !_kIsWeb) {
      loadSync();
    }
    return _valueId;
  }

  @override
  set valueId(int? id) {
    if (_valueId != id) {
      isChanged = true;
      isLoaded = id == null;
      _value = null;
    }
    _valueId = id;
    isIdLoaded = true;
  }

  @override
  Future<void> load() async {
    _value = await filter().findFirst();
    _valueId = _value == null ? null : getId(_value!);
    isChanged = false;
    isLoaded = true;
    isIdLoaded = true;
  }

  @override
  void loadSync() {
    _value = filter().findFirstSync();
    _valueId = _value == null ? null : getId(_value!);
    isChanged = false;
    isLoaded = true;
    isIdLoaded = true;
  }

  @override
  Future<void> save() async {
    if (!isChanged) {
      return;
    }

    final id = valueId;
    await updateIds(link: [if (id != null) id], reset: true);
    isChanged = false;
  }

  @override
  void saveSync() {
    if (!isChanged) {
      return;
    }

    final id = valueId;
    updateIdsSync(link: [if (id != null) id], reset: true);
    isChanged = false;
  }

  @override
  Future<void> reset() async {
    await update(reset: true);
    _value = null;
    _valueId = null;
    isChanged = false;
    isLoaded = true;
    isIdLoaded = true;
  }

  @override
  void resetSync() {
    updateSync(reset: true);
    _value = null;
    _valueId = null;
    isChanged = false;
    isLoaded = true;
    isIdLoaded = true;
  }
}
