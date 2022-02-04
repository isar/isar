import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:isar/src/native/isar_core.dart';

import 'binary_reader.dart';
import 'binary_writer.dart';

List<String> splitWordsCore(String input) {
  initializeIsarCore();

  final bytes = BinaryWriter.utf8Encoder.convert(input);
  final bytesPtr = malloc<Uint8>(bytes.length);
  bytesPtr.asTypedList(bytes.length).setAll(0, bytes);

  final wordCountPtr = malloc<Uint32>();
  final boundariesPtr =
      IC.isar_find_word_boundaries(bytesPtr.cast(), bytes.length, wordCountPtr);
  final wordCount = wordCountPtr.value;
  final boundaries = boundariesPtr.asTypedList(wordCount * 2);

  final words = <String>[];
  for (var i = 0; i < wordCount * 2; i++) {
    final wordBytes = bytes.sublist(boundaries[i++], boundaries[i]);
    words.add(BinaryReader.utf8Decoder.convert(wordBytes));
  }

  IC.isar_free_word_boundaries(boundariesPtr, wordCount);
  malloc.free(bytesPtr);
  malloc.free(wordCountPtr);

  return words;
}
