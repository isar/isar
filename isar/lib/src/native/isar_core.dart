import 'dart:collection';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:isar/src/native/bindings.dart';
import 'package:isar/src/object_id.dart';
import 'package:isar/src/native/object_id_impl.dart';

class IsarCoreUtils {
  static final syncTxnPtr = allocate<Pointer>();
  static final syncRawObjPtr = allocate<RawObject>();
}

IsarCoreBindings? _bindings;
IsarCoreBindings get IsarCore {
  if (_bindings == null) {
    final dylib = DynamicLibrary.open('libisar.so');
    _bindings = IsarCoreBindings(dylib);
  }
  return _bindings!;
}

extension RawObjectX on RawObject {
  ObjectId get oid {
    return ObjectIdImpl(oid_time, oid_rand_counter);
  }

  set oid(ObjectId? oid) {
    if (oid != null) {
      final oidImpl = oid as ObjectIdImpl;
      oid_time = oidImpl.time;
      oid_rand_counter = oidImpl.randCounter;
    } else {
      oid_time = 0;
      oid_rand_counter = 0;
    }
  }
}
