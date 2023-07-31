// ignore_for_file: public_member_api_docs

import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart' as ffi;

export 'dart:ffi';
export 'package:ffi/ffi.dart';

@pragma('vm:prefer-inline')
Pointer<T> ptrFromAddress<T extends NativeType>(int addr) =>
    Pointer.fromAddress(addr);

extension PointerPointerX<T extends NativeType> on Pointer<Pointer<T>> {
  @pragma('vm:prefer-inline')
  Pointer<T> get ptrValue => value;

  @pragma('vm:prefer-inline')
  set ptrValue(Pointer<T> ptr) => value = ptr;

  @pragma('vm:prefer-inline')
  void setPtrAt(int index, Pointer<T> ptr) {
    this[index] = ptr;
  }
}

extension PointerBoolX on Pointer<Bool> {
  @pragma('vm:prefer-inline')
  bool get boolValue => value;
}

extension PointerU8X on Pointer<Uint8> {
  @pragma('vm:prefer-inline')
  Uint8List asU8List(int length) => asTypedList(length);
}

extension PointerUint16X on Pointer<Uint16> {
  @pragma('vm:prefer-inline')
  Uint16List asU16List(int length) => asTypedList(length);
}

extension PointerUint32X on Pointer<Uint32> {
  @pragma('vm:prefer-inline')
  int get u32Value => value;
}

const malloc = ffi.malloc;
final free = ffi.malloc.free;
