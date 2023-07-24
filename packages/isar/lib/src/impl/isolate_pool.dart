part of isar;

class _IsolatePool {
  static final _maxIsolates = Abi.current() == Abi.androidArm ? 4 : 12;

  static int _activeIsolates = 0;
  static final _waiting = <Completer<void>>[];

  static Future<R> runIsolate<R>(R Function() callback, String name) async {
    if (_activeIsolates >= _maxIsolates) {
      final completer = Completer<void>();
      _waiting.add(completer);
      await completer.future;
    }

    _activeIsolates++;
    final result = await Isolate.run(callback, debugName: name);
    _activeIsolates--;

    final nextCompleter = _waiting.isNotEmpty ? _waiting.removeAt(0) : null;
    nextCompleter?.complete();

    return result;
  }
}
