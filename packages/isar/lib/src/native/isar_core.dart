import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:isar/isar.dart';

import 'bindings.dart';

const minInt = -2147483648;
const maxInt = 2147483647;
const minLong = -9223372036854775808;
const maxLong = 9223372036854775807;
const minDouble = double.nan;
const maxDouble = double.infinity;

const nullInt = minInt;
const nullLong = minLong;
const nullFloat = double.nan;
const nullDouble = double.nan;
final nullDate = DateTime.fromMillisecondsSinceEpoch(0);

const nullBool = 0;
const falseBool = 1;
const trueBool = 2;

// ignore: non_constant_identifier_names
IsarCoreBindings? _IC;
// ignore: non_constant_identifier_names
IsarCoreBindings get IC => _IC!;

void initializeIsarCore({Map<Abi, String> libraries = const {}}) {
  if (_IC != null) {
    return;
  }
  late String library;
  if (libraries.containsKey(Abi.current())) {
    library = libraries[Abi.current()]!;
  } else {
    switch (Abi.current()) {
      case Abi.androidArm:
      case Abi.androidArm64:
      case Abi.androidIA32:
      case Abi.androidX64:
        library = 'libisar.so';
        break;
      case Abi.iosArm64:
      case Abi.iosX64:
        break;
      case Abi.macosArm64:
      case Abi.macosX64:
        library = 'libisar.dylib';
        break;
      case Abi.linuxX64:
        library = 'libisar.so';
        break;
      case Abi.windowsX64:
        library = 'isar.dll';
        break;
      default:
        throw 'Unsupported processor architecture "${Abi.current()}".'
            'Please open an issue on GitHub to request it.';
    }
  }

  try {
    if (Platform.isIOS) {
      _IC = IsarCoreBindings(DynamicLibrary.process());
    } else {
      _IC ??= IsarCoreBindings(DynamicLibrary.open(library));
    }
  } catch (e) {
    throw IsarError(
        'Could not initialize IsarCore library. If you create a Flutter app, '
        'make sure to add isar_flutter_libs to your dependencies: $e');
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
  } else {
    return null;
  }
}

@pragma('vm:prefer-inline')
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
  @pragma('vm:prefer-inline')
  bool get isNull => address == 0;
}
