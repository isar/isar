import 'dart:async';
import 'dart:collection';

import 'package:isar/isar.dart';
import 'package:isar/src/native/native.dart';

class IsolatePool {
  IsolatePool.start(int workerCount, IsolatePoolSetup setup) : _setup = setup {
    for (var i = 0; i < workerCount; i++) {
      final worker = IsolateWorker.start(setup);
      pool.add(worker);
    }
  }

  final IsolatePoolSetup _setup;
  final pool = Queue<IsolateWorker>();

  Future<T> request<T>(IsolateRequest<T> request) async {
    if (pool.isEmpty) {
      return Isolate.run(() async {
        final result = await _setup((isar) async => await request(isar));
        return result as T;
      });
    } else {
      final worker = pool.removeFirst();
      pool.add(worker);
      return worker.request(request);
    }
  }

  Future<void> dispose() async {
    final futures = <Future<void>>[];
    for (final worker in pool) {
      futures.add(worker.dispose());
    }
    await Future.wait(futures);
  }
}

typedef IsolateRequest<T> = FutureOr<T> Function(Isar isar);
typedef _IsolateResponse = (dynamic result, Object? error, StackTrace? stack);

class IsolateWorker {
  IsolateWorker._();

  factory IsolateWorker.start(IsolatePoolSetup setup) {
    final resultPort = ReceivePort();
    final exitPort = ReceivePort();
    Isolate.spawn(
      _execute,
      (resultPort.sendPort, setup),
      onError: exitPort.sendPort,
      onExit: exitPort.sendPort,
      debugName: 'Isar Isolate worker',
    );

    final worker = IsolateWorker._();
    exitPort.listen((w) {
      for (final request in worker._queue) {
        request.completeError(
          StateError('Isar worker terminated unexpectedly.\n\n $w'),
        );
      }
      if (!worker._exitCompleter.isCompleted) {
        worker._exitCompleter.complete();
      }
    });

    worker._listen(resultPort);

    return worker;
  }

  final _sendPort = Completer<SendPort>();
  final _queue = Queue<Completer<void>>();
  final _exitCompleter = Completer<void>();

  Future<T> request<T>(IsolateRequest<T> request) async {
    final completer = Completer<dynamic>();
    final sp = await _sendPort.future;
    sp.send(request);
    _queue.add(completer);
    final result = await completer.future;
    return result as T;
  }

  Future<void> _listen(ReceivePort rp) async {
    await for (final message in rp) {
      if (message is SendPort) {
        _sendPort.complete(message);
      } else if (message is _IsolateResponse) {
        final completer = _queue.removeFirst();
        if (message.$2 == null) {
          completer.complete(message.$1);
        } else {
          completer.completeError(message.$2!, message.$3);
        }
      } else {
        // ignore: avoid_print - debug output for unexpected isolate messages
        print('Unknown message: $message');
      }
    }
  }

  Future<void> dispose() async {
    final sp = await _sendPort.future;
    sp.send(null);
    await _exitCompleter.future;
  }

  static Future<void> _execute((SendPort, IsolatePoolSetup) args) async {
    final (sp, setup) = args;
    final rp = ReceivePort();
    sp.send(rp.sendPort);

    await setup((isar) async {
      await for (final msg in rp) {
        if (msg is IsolateRequest) {
          try {
            final result = msg(isar);
            sp.send((result, null, null));
          } on Exception catch (e, stack) {
            sp.send((null, e, stack));
          }
        } else {
          return;
        }
      }
    });
  }
}
