---
title: Maps
---

Isar does not support maps out of the box but it's easy to make use of embedded objects to achieve the same result.

There are multiple ways to implement maps. You could either create an embedded object with a list of keys and a list of values. In this case, we want to support values of different types so we store the map as JSON string instead.

You can also add custom encoding and decoding to support values other than primitives.

This implementation only decodes the map when it is accessed for the first time.

```dart
import 'dart:collection';
import 'dart:convert';

import 'package:isar/isar.dart';

/// A map implementation that can be stored in Isar.
@Embedded(inheritance: false)
class IsarMap<T> with MapMixin<String, T> {
  /// Creates a new, empty IsarMap.
  IsarMap();

  /// Creates a new IsarMap from a [Map].
  IsarMap.from(Map<String, T> other) {
    _map.addAll(other);
  }

  @ignore
  String? _json;

  @ignore
  late final _map = _json == null
      ? <String, dynamic>{}
      : jsonDecode(_json!) as Map<String, dynamic>;

  /// Returns the map as json string.
  String get json => _json ?? jsonEncode(_map);

  /// Sets the map from a json string. This method may only be called right
  /// after the map instance has been created and before any other method has
  /// been called.
  set json(String value) {
    _json = value;
  }

  @override
  @ignore
  Iterable<String> get keys => _map.keys;

  @override
  T? operator [](Object? key) {
    final value = _map[key];
    if (value is T) {
      return value;
    } else {
      return null;
    }
  }

  @override
  void operator []=(String key, T value) {
    assert(
      value is num || value is bool || value is String,
      'IsarMap only supports number, bool and String values.',
    );
    _json = null;
    _map[key] = value;
  }

  @override
  void clear() {
    _json = null;
    _map.clear();
  }

  @override
  T? remove(Object? key) {
    _json = null;
    final value = _map.remove(key);
    if (value is T) {
      return value;
    } else {
      return null;
    }
  }
}
```