import 'dart:ffi';

class RawObject extends Struct {
  @Uint64()
  late int oid;

  late Pointer<Uint8> data;

  @Uint32()
  late int length;
}
