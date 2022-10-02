// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:isar/isar.dart';
import 'package:isar/src/native/bindings.dart';

const Id isarMinId = -9223372036854775807;

const Id isarMaxId = 9223372036854775807;

const Id isarAutoIncrementId = -9223372036854775808;

typedef IsarAbi = Abi;

const int minByte = 0;
const int maxByte = 255;
const int minInt = -2147483648;
const int maxInt = 2147483647;
const int minLong = -9223372036854775808;
const int maxLong = 9223372036854775807;
const double minDouble = double.nan;
const double maxDouble = double.infinity;

const nullByte = IsarObject_NULL_BYTE;
const nullInt = IsarObject_NULL_INT;
const nullLong = IsarObject_NULL_LONG;
const nullFloat = double.nan;
const nullDouble = double.nan;
final nullDate = DateTime.fromMillisecondsSinceEpoch(0);

const nullBool = IsarObject_NULL_BOOL;
const falseBool = IsarObject_FALSE_BOOL;
const trueBool = IsarObject_TRUE_BOOL;

const String _githubUrl = 'https://github.com/isar/isar/releases/download';

bool _isarInitialized = false;

// ignore: non_constant_identifier_names
late final IsarCoreBindings IC;

typedef FinalizerFunction = void Function(Pointer<Void> token);
late final Pointer<NativeFinalizerFunction> isarClose;
late final Pointer<NativeFinalizerFunction> isarQueryFree;

FutureOr<void> initializeCoreBinary({
  Map<Abi, String> libraries = const {},
  bool download = false,
}) {
  if (_isarInitialized) {
    return null;
  }

  String? libraryPath;
  if (!Platform.isIOS) {
    libraryPath = libraries[Abi.current()] ?? Abi.current().localName;
  }

  try {
    _initializePath(libraryPath);
  } catch (e) {
    if (!Platform.isAndroid && !Platform.isIOS) {
      final downloadPath = _getLibraryDownloadPath(libraries);
      if (download) {
        return _downloadIsarCore(downloadPath).then((value) {
          _initializePath(downloadPath);
        });
      } else {
        // try to use the binary at the download path anyway
        _initializePath(downloadPath);
      }
    } else {
      throw IsarError(
        'Could not initialize IsarCore library for processor architecture '
        '"${Abi.current()}". If you create a Flutter app, make sure to add '
        'isar_flutter_libs to your dependencies.\n$e',
      );
    }
  }
}

void _initializePath(String? libraryPath) {
  late DynamicLibrary dylib;
  if (Platform.isIOS) {
    dylib = DynamicLibrary.process();
  } else {
    dylib = DynamicLibrary.open(libraryPath!);
  }

  final bindings = IsarCoreBindings(dylib);

  final coreVersion = bindings.isar_version().cast<Utf8>().toDartString();
  if (coreVersion != Isar.version && coreVersion != 'debug') {
    throw IsarError(
      'Incorrect Isar Core version: Required ${Isar.version} found '
      '$coreVersion. Make sure to use the latest isar_flutter_libs. If you '
      'have a Dart only project, make sure that old Isar Core binaries are '
      'deleted.',
    );
  }

  IC = bindings;
  isarClose = dylib.lookup('isar_instance_close');
  isarQueryFree = dylib.lookup('isar_q_free');
  _isarInitialized = true;
}

String _getLibraryDownloadPath(Map<Abi, String> libraries) {
  final providedPath = libraries[Abi.current()];
  if (providedPath != null) {
    return providedPath;
  } else {
    final name = Abi.current().localName;
    if (Platform.script.path.isEmpty) {
      return name;
    }
    var dir = Platform.script.pathSegments
        .sublist(0, Platform.script.pathSegments.length - 1)
        .join(Platform.pathSeparator);
    if (!Platform.isWindows) {
      // Not on windows, add leading platform path separator
      dir = '${Platform.pathSeparator}$dir';
    }
    return '$dir${Platform.pathSeparator}$name';
  }
}

Future<void> _downloadIsarCore(String libraryPath) async {
  final libraryFile = File(libraryPath);
  // ignore: avoid_slow_async_io
  if (await libraryFile.exists()) {
    return;
  }
  final remoteName = Abi.current().remoteName;
  final uri = Uri.parse('$_githubUrl/${Isar.version}/$remoteName');
  final request = await HttpClient().getUrl(uri);
  final response = await request.close();
  if (response.statusCode != 200) {
    throw IsarError(
      'Could not download IsarCore library: ${response.reasonPhrase}',
    );
  }
  await response.pipe(libraryFile.openWrite());
}

IsarError? isarErrorFromResult(int result) {
  if (result != 0) {
    final error = IC.isar_get_error(result);
    if (error.address == 0) {
      throw IsarError(
        'There was an error but it could not be loaded from IsarCore.',
      );
    }
    try {
      final message = error.cast<Utf8>().toDartString();
      return IsarError(message);
    } finally {
      IC.isar_free_string(error);
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
  final portStreamController = StreamController<void>(onCancel: port.close);
  port.listen((event) {
    if (event == 0) {
      portStreamController.add(null);
    } else {
      final error = isarErrorFromResult(event as int);
      portStreamController.addError(error!);
    }
  });
  return portStreamController.stream;
}

extension PointerX on Pointer {
  @pragma('vm:prefer-inline')
  bool get isNull => address == 0;
}

extension on Abi {
  String get localName {
    switch (Abi.current()) {
      case Abi.androidArm:
      case Abi.androidArm64:
      case Abi.androidIA32:
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
      default:
        throw IsarError(
          'Unsupported processor architecture "${Abi.current()}". '
          'Please open an issue on GitHub to request it.',
        );
    }
  }

  String get remoteName {
    switch (Abi.current()) {
      case Abi.macosArm64:
      case Abi.macosX64:
        return 'libisar_macos.dylib';
      case Abi.linuxX64:
        return 'libisar_linux_x64.so';
      case Abi.windowsArm64:
        return 'isar_windows_arm64.dll';
      case Abi.windowsX64:
        return 'isar_windows_x64.dll';
    }
    throw UnimplementedError();
  }
}
