import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:isar/isar.dart';
import 'package:isar/src/web/interop.dart';
import 'package:web/web.dart';

export 'bindings.dart';
export 'ffi.dart';
export 'interop.dart';

typedef IsarCoreBindings = JSIsar;

const tryInline = pragma('dart2js:tryInline');

class ReceivePort extends Stream<dynamic> {
  final sendPort = SendPort();

  @override
  StreamSubscription<void> listen(
    void Function(dynamic event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    throw UnimplementedError();
  }

  void close() {
    throw UnimplementedError();
  }
}

class SendPort {
  int get nativePort => 0;

  void send(dynamic message) {
    throw UnimplementedError();
  }
}

class IsarCorePlatformImpl implements IsarCorePlatform {
  const IsarCorePlatformImpl();

  @override
  // ignore: invalid_runtime_check_with_js_interop_types, invalid_override - web platform specific
  FutureOr<IsarCoreBindings> initializeBindings([String? library]) async {
    final url = library ?? 'https://unpkg.com/isar@${Isar.version}/isar.wasm';

    final env = JSObject()..['js_error'] = _jsError.toJS;
    final import = JSObject()..['env'] = env;

    final promise = WebAssembly.instantiateStreaming(
      window.fetch(url.toJS),
      import,
    );
    final wasm = await promise.toDart;
    return wasm.instance.exports as IsarCoreBindings;
  }

  void _jsError(int ptr) {
    // ignore: invalid_runtime_check_with_js_interop_types - This is web-specific FFI code, cast is intentional.
    final buffer = (IsarCore.b as JSIsar).u8Heap;
    var strLen = 0;
    var i = ptr;
    while (buffer[i] != 0) {
      strLen++;
      i++;
    }
    final str = utf8.decode(buffer.sublist(ptr, ptr + strLen));
    // ignore: avoid_print - debug output for WebAssembly errors
    print(str);
  }

  // based on https://github.com/tjwebb/fnv-plus
  @override
  int fastHash(String str) {
    var i = 0;
    var t0 = 0;
    var v0 = 0x2325;
    var t1 = 0;
    var v1 = 0x8422;
    var t2 = 0;
    var v2 = 0x9ce4;
    var t3 = 0;
    var v3 = 0xcbf2;

    while (i < str.length) {
      v0 ^= str.codeUnitAt(i++);
      t0 = v0 * 435;
      t1 = v1 * 435;
      t2 = v2 * 435;
      t3 = v3 * 435;
      t2 += v0 << 8;
      t3 += v1 << 8;
      t1 += t0 >>> 16;
      v0 = t0 & 65535;
      t2 += t1 >>> 16;
      v1 = t1 & 65535;
      v3 = (t3 + (t2 >>> 16)) & 65535;
      v2 = t2 & 65535;
    }

    return (v3 & 15) * 281474976710656 +
        v2 * 4294967296 +
        v1 * 65536 +
        (v0 ^ (v3 >> 4));
  }

  @override
  void startIsolatePool(Isar isar, int workerCount, IsolatePoolSetup setup) {}

  @override
  Future<void> disposeIsolatePool(Isar isar) {
    return Future.value();
  }

  /// @nodoc
  @tryInline
  @override
  Future<T> runIsolate<T>(
    FutureOr<T> Function(Isar? isar) computation, {
    Isar? isar,
  }) {
    final result = computation(isar);
    if (result is Future<T>) {
      return result;
    } else {
      return Future.value(result);
    }
  }
}
