import 'dart:ffi';

class RawObject extends Struct {
  @Uint64()
  int oid;

  Pointer<Uint8> data;

  @Uint32()
  int length;
}
