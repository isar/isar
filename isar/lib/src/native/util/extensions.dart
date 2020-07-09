import 'dart:typed_data';

extension Uint8ListX on Uint8List {
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int readUint32(int offset) {
    return this[offset] |
        this[offset + 1] << 8 |
        this[offset + 2] << 16 |
        this[offset + 3] << 24;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeUint32(int offset, int value) {
    this[offset] = value;
    this[offset + 1] = value >> 8;
    this[offset + 2] = value >> 16;
    this[offset + 3] = value >> 24;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeUint64(int offset, int value) {
    this[offset] = value;
    this[offset + 1] = value >> 8;
    this[offset + 2] = value >> 16;
    this[offset + 3] = value >> 24;
    this[offset + 4] = value >> 32;
    this[offset + 5] = value >> 40;
    this[offset + 6] = value >> 48;
    this[offset + 7] = value >> 56;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  Uint8List view(int offset, int bytes) {
    return Uint8List.view(buffer, offsetInBytes + offset, bytes);
  }
}
