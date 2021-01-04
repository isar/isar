part of isar_native;

void nCall(int result) {
  if (result != 0) {
    throw 'ERROR: $result';
  }
}

int nBool(bool value) {
  if (value) {
    return 1;
  } else {
    return 0;
  }
}
