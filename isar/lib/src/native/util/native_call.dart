part of isar_native;

void nCall(int result) {
  if (result != 0) {
    final error = IC.isar_get_error(result);
    if (error.address == 0) {
      throw IsarError(
          'There was an error but it could not be loaded from IsarCore.');
    }
    try {
      final message = Utf8.fromUtf8(error.cast());
      throw IsarError(message);
    } finally {
      IC.isar_free_error(error);
    }
  }
}

int nBool(bool value) {
  if (value) {
    return 1;
  } else {
    return 0;
  }
}
