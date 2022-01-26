import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:isar/isar.dart';

import 'bindings.dart';

const falseBool = 1;
const trueBool = 2;

const minInt = -2147483648;
const maxInt = 2147483647;
const minLong = -9223372036854775808;
const maxLong = 9223372036854775807;
const minFloat = double.nan;
const maxFloat = double.infinity;
const minDouble = double.nan;
const maxDouble = double.infinity;
final minDate = DateTime.fromMicrosecondsSinceEpoch(minLong, isUtc: true);

const nullBool = 0;
const nullInt = minInt;
const nullLong = minLong;
const nullFloat = minFloat;
const nullDouble = minDouble;
final nullDate = minDate;

// ignore: non_constant_identifier_names
IsarCoreBindings? _IC;
// ignore: non_constant_identifier_names
IsarCoreBindings get IC => _IC!;

void initializeIsarCore({Map<String, String> libraries = const {}}) {
  if (_IC != null) {
    return;
  }
  late String library;
  if (Platform.isAndroid) {
    library = libraries['android'] ?? 'libisar.so';
  } else if (Platform.isMacOS) {
    library = libraries['macos'] ?? 'libisar.dylib';
  } else if (Platform.isWindows) {
    library = libraries['windows'] ?? 'isar.dll';
  } else if (Platform.isLinux) {
    library = libraries['linux'] ?? 'libisar.so';
  }
  try {
    if (Platform.isIOS) {
      _IC = IsarCoreBindings(DynamicLibrary.process());
    } else {
      _IC ??= IsarCoreBindings(DynamicLibrary.open(library));
    }
  } catch (e) {
    print(e);
    throw IsarError(
        'Could not initialize IsarCore library. If you create a Flutter app, '
        'make sure to add isar_flutter_libs to your dependencies.');
  }
}

IsarError? isarErrorFromResult(int result) {
  if (result != 0) {
    final error = IC.isar_get_error(result);
    if (error.address == 0) {
      throw IsarError(
          'There was an error but it could not be loaded from IsarCore.');
    }
    try {
      final message = error.cast<Utf8>().toDartString();
      return IsarError(message);
    } finally {
      IC.isar_free_error(error);
    }
  }
}

void nCall(int result) {
  final error = isarErrorFromResult(result);
  if (error != null) {
    throw error;
  }
}

Stream<void> wrapIsarPort(ReceivePort port) {
  final portStreamController = StreamController<void>.broadcast();
  port.listen(
    (event) {
      if (event == 0) {
        portStreamController.add(null);
      } else {
        portStreamController.addError(isarErrorFromResult(event)!);
      }
    },
    onDone: () {
      portStreamController.close();
    },
  );
  return portStreamController.stream;
}

extension RawObjectX on RawObject {
  void freeData() {
    if (buffer.address != 0) {
      malloc.free(buffer);
      buffer = nullptr;
    }
  }
}

extension RawObjectSetPointerX on Pointer<RawObjectSet> {
  void free({bool freeData = false}) {
    final objectsPtr = ref.objects;
    if (freeData) {
      for (var i = 0; i < ref.length; i++) {
        final rawObj = objectsPtr.elementAt(i).ref;
        rawObj.freeData();
      }
    }
    malloc.free(objectsPtr);
    malloc.free(this);
  }
}

extension PointerX on Pointer {
  bool get isNull => address == 0;
}
