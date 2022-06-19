import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:isar/isar.dart';
import 'package:isar/src/version.dart';

import 'bindings.dart';

const minInt = -2147483648;
const maxInt = 2147483647;
const minLong = -9223372036854775808;
const maxLong = 9223372036854775807;
const minDouble = double.nan;
const maxDouble = double.infinity;

const nullInt = IsarObject_NULL_INT;
const nullLong = IsarObject_NULL_LONG;
const nullFloat = double.nan;
const nullDouble = double.nan;
final nullDate = DateTime.fromMillisecondsSinceEpoch(0);

const nullBool = IsarObject_NULL_BYTE;
const falseBool = IsarObject_FALSE_BYTE;
const trueBool = IsarObject_TRUE_BYTE;

const _githubUrl = 'https://github.com/isar/isar-core/releases/download';

var _isarInitialized = false;
bool get isarInitialized => _isarInitialized;

// ignore: non_constant_identifier_names
late final IsarCoreBindings IC;

typedef FinalizerFunction = void Function(Pointer<Void> token);
late final Pointer<NativeFinalizerFunction> isarClose;
late final Pointer<NativeFinalizerFunction> isarQueryFree;

FutureOr<void> initializeCoreBinary(
    {Map<Abi, String> libraries = const {}, bool download = false}) {
  if (_isarInitialized) return null;

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
  final binaryVersion = bindings.isar_version();
  if (binaryVersion != 0 && binaryVersion != isarCoreVersionNumber) {
    throw 'Incorrect Isar binary: Required $isarCoreVersionNumber found $binaryVersion.';
  }

  IC = bindings;
  isarClose = dylib.lookup('isar_close_instance');
  isarQueryFree = dylib.lookup('isar_q_free');
  _isarInitialized = true;
}

String _getLibraryDownloadPath(Map<Abi, String> libraries) {
  final providedPath = libraries[Abi.current()];
  if (providedPath != null) {
    return providedPath;
  } else {
    final name = Abi.current().localName;
    final dirSegments = Platform.script.path.split(Platform.pathSeparator);
    if (dirSegments.isNotEmpty) {
      final dir = dirSegments
          .sublist(0, dirSegments.length - 1)
          .join(Platform.pathSeparator);
      return '$dir${Platform.pathSeparator}$name';
    } else {
      return name;
    }
  }
}

Future<void> _downloadIsarCore(String libraryPath) async {
  final libraryFile = File(libraryPath);
  if (await libraryFile.exists()) {
    return;
  }
  final remoteName = Abi.current().remoteName;
  final uri = Uri.parse('$_githubUrl/$isarCoreVersion/$remoteName');
  final request = await HttpClient().getUrl(uri);
  final response = await request.close();
  if (response.statusCode != 200) {
    throw IsarError(
        'Could not download IsarCore library: ${response.reasonPhrase}');
  }
  await response.pipe(libraryFile.openWrite());
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
        final error = isarErrorFromResult(event as int);
        portStreamController.addError(error!);
      }
    },
    onDone: () {
      portStreamController.close();
    },
  );
  return portStreamController.stream;
}

extension CObjectX on CObject {
  void freeData() {
    if (buffer.address != 0) {
      malloc.free(buffer);
      buffer = nullptr;
    }
  }
}

extension CObjectSetPointerX on Pointer<CObjectSet> {
  void free({bool freeData = false}) {
    final objectsPtr = ref.objects;
    if (freeData) {
      for (var i = 0; i < ref.length; i++) {
        final cObj = objectsPtr.elementAt(i).ref;
        cObj.freeData();
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
        throw 'Unsupported processor architecture "${Abi.current()}".'
            'Please open an issue on GitHub to request it.';
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
