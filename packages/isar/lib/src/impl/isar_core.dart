import 'dart:ffi';

import 'package:isar/src/impl/bindings.dart';

// ignore: non_constant_identifier_names
late final IsarCoreBindings IC;

extension StringPointer on String {
  Pointer<Uint16> toUtf16Pointer(Allocator alloc) {
    final ptr = alloc<Uint16>(length);
    for (var i = 0; i < length; i++) {
      ptr[i] = codeUnitAt(i);
    }
    return ptr;
  }
}
