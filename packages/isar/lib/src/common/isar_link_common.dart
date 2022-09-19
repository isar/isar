import 'package:isar/isar.dart';
import 'package:isar/src/common/isar_link_base_impl.dart';

const bool _kIsWeb = identical(0, 0.0);

/// @nodoc
abstract class IsarLinkCommon<OBJ> extends IsarLinkBaseImpl<OBJ>
    with IsarLink<OBJ> {
  OBJ? _value;

  @override
  bool isChanged = false;

  @override
  bool isLoaded = false;

  @override
  OBJ? get value {
    if (isAttached && !isLoaded && !isChanged && !_kIsWeb) {
      loadSync();
    }
    return _value;
  }

  @override
  set value(OBJ? value) {
    isChanged |= !identical(_value, value);
    _value = value;
    isLoaded = true;
  }

  @override
  Future<void> load() async {
    _value = await filter().findFirst();
    isChanged = false;
    isLoaded = true;
  }

  @override
  void loadSync() {
    _value = filter().findFirstSync();
    isChanged = false;
    isLoaded = true;
  }

  @override
  Future<void> save() async {
    if (!isChanged) {
      return;
    }

    final object = value;

    await update(link: [if (object != null) object], reset: true);
    isChanged = false;
    isLoaded = true;
  }

  @override
  void saveSync() {
    if (!isChanged) {
      return;
    }

    final object = _value;
    updateSync(link: [if (object != null) object], reset: true);

    isChanged = false;
    isLoaded = true;
  }

  @override
  Future<void> reset() async {
    await update(reset: true);
    _value = null;
    isChanged = false;
    isLoaded = true;
  }

  @override
  void resetSync() {
    updateSync(reset: true);
    _value = null;
    isChanged = false;
    isLoaded = true;
  }

  @override
  String toString() {
    return 'IsarLink($_value)';
  }
}
