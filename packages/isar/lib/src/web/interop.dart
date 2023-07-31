// ignore_for_file: public_member_api_docs, non_constant_identifier_names

import 'dart:typed_data';

import 'package:js/js.dart';

@JS()
@staticInterop
class JSWindow {}

extension JSWIndowX on JSWindow {
  external JSIsar get isar;

  external JSWasm get WebAssembly;

  external Object fetch(String url);
}

@JS()
@staticInterop
class JSWasm {}

extension JSWasmX on JSWasm {
  external Object instantiateStreaming(Object source, dynamic importObject);
}

@JS()
@staticInterop
class JSWasmModule {}

extension JSWasmModuleX on JSWasmModule {
  external JSWasmInstance get instance;
}

@JS()
@staticInterop
class JSWasmInstance {}

extension JSWasmInstanceX on JSWasmInstance {
  external JSIsar get exports;
}

@JS()
@staticInterop
class JSIsar {}

extension JSIsarX on JSIsar {
  external JsMemory get memory;

  Uint8List get u8Heap => memory.buffer.asUint8List();

  Uint16List get u16Heap => memory.buffer.asUint16List();

  Uint32List get u32Heap => memory.buffer.asUint32List();

  external int malloc(int byteCount);

  external void free(int ptrAddress);
}

@JS()
@staticInterop
class JsMemory {}

@JS()
@staticInterop
extension on JsMemory {
  external ByteBuffer get buffer;
}
