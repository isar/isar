import 'dart:isolate';
import 'dart:ffi';

void main() {
  for (var i = 0; i < 10; i++) {
    var s = Stopwatch()..start();
    for (var i = 0; i < 1000; i++) {
      final t = ReceivePort();
      //final s = t.sendPort.nativePort;
    }
    print(s.elapsedMicroseconds);
  }
}
