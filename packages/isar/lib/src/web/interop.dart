import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' hide Uint32List;

extension type JSIsar(JSObject _) implements JSObject {
  external Memory get memory;

  Uint8List get u8Heap => Uint8List.view(memory.buffer.toDart);

  Uint16List get u16Heap => Uint16List.view(memory.buffer.toDart);

  Uint32List get u32Heap => Uint32List.view(memory.buffer.toDart);

  external int malloc(int byteCount);

  external void free(int ptrAddress);
}
