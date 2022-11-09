import 'dart:ffi';

String getRustTarget() {
  switch (Abi.current()) {
    case Abi.macosArm64:
      return 'aarch64-apple-darwin';
    case Abi.macosX64:
      return 'x86_64-apple-darwin';
    case Abi.linuxArm64:
      return 'aarch64-unknown-linux-gnu';
    case Abi.linuxX64:
      return 'x86_64-unknown-linux-gnu';
    case Abi.windowsX64:
      return 'x86_64-pc-windows-msvc';
    default:
      throw UnsupportedError('Unsupported ABI: ${Abi.current()}');
  }
}
