import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:isar/src/native/encode_string.dart';
import 'package:isar/src/native/isar_core.dart';
import 'package:isar/src/native/isar_reader_impl.dart';

// ignore: public_member_api_docs
List<String> isarSplitWords(String input) {
  initializeCoreBinary();

  final bytesPtr = malloc<Uint8>(input.length * 3);
  final bytes = bytesPtr.asTypedList(input.length * 3);
  final byteCount = encodeString(input, bytes, 0);

  final wordCountPtr = malloc<Uint32>();
  final boundariesPtr =
      IC.isar_find_word_boundaries(bytesPtr.cast(), byteCount, wordCountPtr);
  final wordCount = wordCountPtr.value;
  final boundaries = boundariesPtr.asTypedList(wordCount * 2);

  final words = <String>[];
  for (var i = 0; i < wordCount * 2; i++) {
    final wordBytes = bytes.sublist(boundaries[i++], boundaries[i]);
    words.add(IsarReaderImpl.utf8Decoder.convert(wordBytes));
  }

  IC.isar_free_word_boundaries(boundariesPtr, wordCount);
  malloc.free(bytesPtr);
  malloc.free(wordCountPtr);

  return words;
}
