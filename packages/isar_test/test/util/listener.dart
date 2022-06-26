import 'dart:async';

import 'package:test/test.dart';

class Listener<T> {
  Listener(Stream<T> stream) {
    subscription = stream.listen((event) {
      if (_completer != null) {
        _completer!.complete(event);
        _completer = null;
      } else {
        _unprocessed.add(event);
      }
    });
  }
  late StreamSubscription<void> subscription;
  final List<T> _unprocessed = <T>[];
  Completer<T>? _completer;

  Future<T> get next {
    if (_unprocessed.isEmpty) {
      expect(_completer, null);
      _completer = Completer<T>();
      return _completer!.future;
    } else {
      return Future.value(_unprocessed.removeAt(0));
    }
  }

  Future<void> done() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await subscription.cancel();
    expect(_completer, null);
    expect(_unprocessed, <dynamic>[]);
  }
}
