part of isar_native;

IsarError? isarErrorFromResult(int result) {
  if (result != 0) {
    final error = IC.isar_get_error(result);
    if (error.address == 0) {
      throw IsarError(
          'There was an error but it could not be loaded from IsarCore.');
    }
    try {
      final message = Utf8.fromUtf8(error.cast());
      return IsarError(message);
    } finally {
      IC.isar_free_error(error);
    }
  }
}

void nCall(int result) {
  final error = isarErrorFromResult(result);
  if (error != null) {
    throw error;
  }
}

Stream<void> wrapIsarPort(ReceivePort port) {
  final portStreamController = StreamController<Null>.broadcast();
  port.listen(
    (event) {
      if (event == 0) {
        portStreamController.add(null);
      } else {
        portStreamController.addError(isarErrorFromResult(event)!);
      }
    },
    onDone: () {
      portStreamController.close();
    },
  );
  return portStreamController.stream;
}
