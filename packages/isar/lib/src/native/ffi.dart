// ignore_for_file: public_member_api_docs

import 'dart:typed_data';
import 'package:ffi/ffi.dart' as ffi;
import 'package:isar/src/native/native.dart';

export 'dart:ffi';
export 'package:ffi/ffi.dart';

@tryInline
Pointer<T> ptrFromAddress<T extends NativeType>(int addr) =>
    Pointer.fromAddress(addr);

extension PointerPointerX<T extends NativeType> on Pointer<Pointer<T>> {
  @tryInline
  Pointer<T> get ptrValue => value;

  @tryInline
  set ptrValue(Pointer<T> ptr) => value = ptr;

  @tryInline
  void setPtrAt(int index, Pointer<T> ptr) {
    this[index] = ptr;
  }
}

extension PointerBoolX on Pointer<Bool> {
  @tryInline
  bool get boolValue => value;
}

extension PointerU8X on Pointer<Uint8> {
  @tryInline
  Uint8List asU8List(int length) => asTypedList(length);
}

extension PointerUint16X on Pointer<Uint16> {
  @tryInline
  Uint16List asU16List(int length) => asTypedList(length);
}

extension PointerUint32X on Pointer<Uint32> {
  @tryInline
  int get u32Value => value;
}

const malloc = ffi.malloc;
final free = ffi.malloc.free;
