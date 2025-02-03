import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:isar/isar.dart';
import 'package:isar/src/native/bindings.dart';

export 'dart:isolate';

export 'bindings.dart';
export 'ffi.dart';

/// @nodoc
FutureOr<IsarCoreBindings> initializePlatformBindings([String? library]) {
  late IsarCoreBindings bindings;
  try {
    library ??= Platform.isIOS ? null : library ?? Abi.current().localName;

    final dylib = Platform.isIOS
        ? DynamicLibrary.process()
        : DynamicLibrary.open(library!);
    bindings = IsarCoreBindings(dylib);
  } catch (e) {
    throw IsarNotReadyError(
      'Could not initialize IsarCore library for processor architecture '
      '"${Abi.current()}". If you create a Flutter app, make sure to add '
      'isar_flutter_libs to your dependencies. For Dart-only apps or unit '
      'tests, make sure to place the correct Isar binary in the correct '
      'directory.\n$e',
    );
  }

  final coreVersion = bindings.isar_version().cast<Utf8>().toDartString();
  if (coreVersion != Isar.version && coreVersion != 'debug') {
    throw IsarNotReadyError(
      'Incorrect Isar Core version: Required ${Isar.version} found '
      '$coreVersion. Make sure to use the latest isar_flutter_libs. If you '
      'have a Dart only project, make sure that old Isar Core binaries are '
      'deleted.',
    );
  }

  bindings.isar_connect_dart_api(NativeApi.initializeApiDLData);

  return bindings;
}

/// @nodoc
const tryInline = pragma('vm:prefer-inline');

extension on Abi {
  String get localName {
    switch (Abi.current()) {
      case Abi.androidArm:
      case Abi.androidArm64:
      case Abi.androidX64:
        return 'libisar.so';
      case Abi.macosArm64:
      case Abi.macosX64:
        return 'libisar.dylib';
      case Abi.linuxX64:
        return 'libisar.so';
      case Abi.windowsArm64:
      case Abi.windowsX64:
        return 'isar.dll';
      case Abi.androidIA32:
        throw IsarNotReadyError(
          'Unsupported processor architecture. X86 Android emulators are not '
          'supported. Please use an x86_64 emulator instead. All physical '
          'Android devices are supported including 32bit ARM.',
        );
      default:
        throw IsarNotReadyError(
          'Unsupported processor architecture "${Abi.current()}". '
          'Please open an issue on GitHub to request it.',
        );
    }
  }
}

int platformFastHash(String string) {
  // ignore: avoid_js_rounded_ints
  const fnvOffsetBasis = 0xcbf29ce484222325;
  const fnvPrime = 0x00000100000001B3;

  var hash = fnvOffsetBasis;

  for (var i = 0; i < string.length; i++) {
    final codeUnit = string.codeUnitAt(i);

    // Process lower byte first (FNV-1a is little-endian)
    hash ^= codeUnit & 0xFF;
    hash *= fnvPrime;

    // Process upper byte if it's part of the UTF-16 representation
    hash ^= codeUnit >> 8;
    hash *= fnvPrime;
  }

  return hash;
}

/// @nodoc
@tryInline
Future<T> runIsolate<T>(
  String debugName,
  FutureOr<T> Function() computation,
) {
  return Isolate.run(computation, debugName: debugName);
}
