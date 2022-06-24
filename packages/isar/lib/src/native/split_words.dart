import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'binary_reader.dart';
import 'binary_writer.dart';
import 'isar_core.dart';

List<String> splitWordsCore(String input) {
  initializeCoreBinary();

  final Uint8List bytes = BinaryWriter.utf8Encoder.convert(input);
  final Pointer<Uint8> bytesPtr = malloc<Uint8>(bytes.length);
  bytesPtr.asTypedList(bytes.length).setAll(0, bytes);

  final Pointer<Uint32> wordCountPtr = malloc<Uint32>();
  final Pointer<Uint32> boundariesPtr =
      IC.isar_find_word_boundaries(bytesPtr.cast(), bytes.length, wordCountPtr);
  final int wordCount = wordCountPtr.value;
  final Uint32List boundaries = boundariesPtr.asTypedList(wordCount * 2);

  final List<String> words = <String>[];
  for (int i = 0; i < wordCount * 2; i++) {
    final Uint8List wordBytes = bytes.sublist(boundaries[i++], boundaries[i]);
    words.add(BinaryReader.utf8Decoder.convert(wordBytes));
  }

  IC.isar_free_word_boundaries(boundariesPtr, wordCount);
  malloc.free(bytesPtr);
  malloc.free(wordCountPtr);

  return words;
}
