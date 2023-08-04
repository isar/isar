import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

final _maxIsolates = Abi.current() == Abi.androidArm ? 4 : 12;

int _activeIsolates = 0;
final _waiting = <Completer<void>>[];

Future<R> scheduleIsolate<R>(
  FutureOr<R> Function() callback, {
  String? debugName,
}) async {
  if (_activeIsolates >= _maxIsolates) {
    final completer = Completer<void>();
    _waiting.add(completer);
    await completer.future;
  }

  _activeIsolates++;
  final result = await Isolate.run(callback, debugName: debugName);
  _activeIsolates--;

  final nextCompleter = _waiting.isNotEmpty ? _waiting.removeAt(0) : null;
  nextCompleter?.complete();

  return result;
}
