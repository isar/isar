import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:isar/isar.dart';

import 'bindings.dart';

const nullBool = 0;
const falseBool = 1;
const trueBool = 2;

const minBool = nullBool;
const maxBool = trueBool;
const minInt = -2147483648;
const maxInt = 2147483647;
const minLong = -9223372036854775808;
const maxLong = 9223372036854775807;
const minFloat = double.nan;
const maxFloat = double.infinity;
const minDouble = double.nan;
const maxDouble = double.infinity;
final minDate = DateTime.fromMillisecondsSinceEpoch(minLong);
final maxDate = DateTime.fromMillisecondsSinceEpoch(maxLong);

const nullInt = minInt;
const nullLong = minLong;
const nullFloat = minFloat;
const nullDouble = minDouble;
final nullDate = minDate;

class IsarCoreUtils {
  static final nullPtr = Pointer.fromAddress(0);
  static final syncTxnPtr = malloc<Pointer>();
  static final syncRawObjPtr = malloc<RawObject>();
}

// ignore: non_constant_identifier_names
IsarCoreBindings? _IC;
// ignore: non_constant_identifier_names
IsarCoreBindings get IC => _IC!;

void initializeIsarCore({Map<String, String> dylibs = const {}}) {
  if (_IC != null) {
    return;
  }
  late String dylib;
  if (Platform.isAndroid) {
    dylib = dylibs['android'] ?? 'libisar.so';
  } else if (Platform.isMacOS) {
    dylib = dylibs['macos'] ?? 'libisar.dylib';
  } else if (Platform.isWindows) {
    dylib = dylibs['windows'] ?? 'isar.dll';
  } else if (Platform.isLinux) {
    dylib = dylibs['linux'] ?? 'libisar.so';
  }
  try {
    if (Platform.isIOS) {
      _IC = IsarCoreBindings(DynamicLibrary.process());
    } else {
      _IC ??= IsarCoreBindings(DynamicLibrary.open(dylib));
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
    }
  }
}

extension PointerX on Pointer {
  bool get isNull => address == 0;
}
