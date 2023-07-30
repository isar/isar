import 'dart:typed_data';

import 'package:isar/isar.dart';
import 'package:isar/src/web/interop.dart';

sealed class NativeType {}

typedef Pointer<T> = int;

@pragma('dart2js:tryInline')
Pointer<T> newPtr<T>(int addr) => addr;

extension PointerX on int {
  @pragma('dart2js:tryInline')
  Pointer<T> cast<T>() => this;

  @pragma('dart2js:tryInline')
  Pointer<void> get ptrValue => IsarCore.b.u32Heap[address ~/ 4];

  @pragma('dart2js:tryInline')
  set ptrValue(Pointer<void> ptr) => IsarCore.b.u32Heap[address ~/ 4] = ptr;

  @pragma('dart2js:tryInline')
  void setPtrAt(int index, Pointer<void> ptr) {
    IsarCore.b.u32Heap[address ~/ 4 + index] = ptr;
  }

  @pragma('dart2js:tryInline')
  bool get boolValue => IsarCore.b.u8Heap[address] != 0;

  @pragma('dart2js:tryInline')
  int get u32Value => IsarCore.b.u32Heap[address ~/ 4];

  @pragma('dart2js:tryInline')
  int get address => this;

  @pragma('dart2js:tryInline')
  Uint8List asU8List(int length) =>
      IsarCore.b.u8Heap.buffer.asUint8List(address, length);

  @pragma('dart2js:tryInline')
  Uint16List asU16List(int length) =>
      IsarCore.b.u16Heap.buffer.asUint16List(address, length);
}

const nullptr = 0;

class Native<T> {
  const Native({String? symbol});
}

class Void extends NativeType {}

class Bool extends NativeType {}

class Uint8 extends NativeType {}

class Int8 extends NativeType {}

class Uint16 extends NativeType {}

class Uint32 extends NativeType {}

typedef Char = Uint8;

class Int32 extends NativeType {}

class Int64 extends NativeType {}

class Float extends NativeType {}

class Double extends NativeType {}

class Opaque extends NativeType {}

class NativeFunction<T> extends NativeType {}

const _sizes = {
  int: 4, // pointer
  Void: 0,
  Bool: 1,
  Uint8: 1,
  Int8: 1,
  Uint16: 2,
  Uint32: 4,
  Int32: 4,
  Int64: 8,
  Float: 4,
  Double: 8,
};

Pointer<T> malloc<T>([int length = 1]) {
  final addr = IsarCore.b.malloc(length * _sizes[T]!);
  return addr;
}

void free(Pointer<NativeType> ptr) {
  IsarCore.b.free(ptr.address);
}
