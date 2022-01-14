import 'package:isar/isar.dart';

import 'isar_core.dart';
import 'isar_collection_impl.dart';
import 'native_query_builder.dart';

final _keyPtrPtr = malloc<Pointer>();

Pointer<NativeType> buildIndexKey(
    IsarCollectionImpl col, String indexName, List<Object?> values) {
  final types = col.indexTypes[indexName]!;
  if (values.length > types.length) {
    throw 'Invalid values for index $indexName';
  }

  IC.isar_key_create(_keyPtrPtr);
  final keyPtr = _keyPtrPtr.value;

  for (var i = 0; i < values.length; i++) {
    _addKeyValue(keyPtr, values[i], types[i]);
  }

  return keyPtr;
}

Pointer<NativeType> buildLowerUnboundedIndexKey(IsarCollectionImpl col) {
  IC.isar_key_create(_keyPtrPtr);
  return _keyPtrPtr.value;
}

Pointer<NativeType> buildUpperUnboundedIndexKey(IsarCollectionImpl col) {
  IC.isar_key_create(_keyPtrPtr);
  final keyPtr = _keyPtrPtr.value;
  IC.isar_key_add_long(keyPtr, maxLong);

  return keyPtr;
}

void _addKeyValue(
    Pointer<NativeType> keyPtr, Object? value, NativeIndexType type) {
  switch (type) {
    case NativeIndexType.bool:
      if (value is bool?) {
        IC.isar_key_add_byte(keyPtr, boolToByte(value));
        return;
      }
      break;
    case NativeIndexType.int:
      if (value is int?) {
        IC.isar_key_add_int(keyPtr, value ?? nullInt);
        return;
      }
      break;
    case NativeIndexType.float:
      if (value is double?) {
        IC.isar_key_add_float(keyPtr, value ?? nullFloat);
        return;
      }
      break;
    case NativeIndexType.long:
      if (value is int?) {
        IC.isar_key_add_long(keyPtr, value ?? nullLong);
        return;
      }
      break;
    case NativeIndexType.double:
      if (value is double?) {
        IC.isar_key_add_double(keyPtr, value ?? nullDouble);
        return;
      }
      break;
    case NativeIndexType.string:
    case NativeIndexType.stringCIS:
      final strPtr = _strToNative(value as String?);
      IC.isar_key_add_string(keyPtr, strPtr, type == NativeIndexType.string);
      _freeStr(strPtr);
      break;
    case NativeIndexType.stringHash:
    case NativeIndexType.stringHashCIS:
      final strPtr = _strToNative(value as String?);
      IC.isar_key_add_string_hash(
          keyPtr, strPtr, type == NativeIndexType.stringHash);
      _freeStr(strPtr);
      break;
    case NativeIndexType.bytesHash:
      if (value is Uint8List) {
        final bytesPtr = malloc<Uint8>(value.length);
        bytesPtr.asTypedList(value.length).setAll(0, value);
        IC.isar_key_add_byte_list_hash(keyPtr, bytesPtr, value.length);
        malloc.free(bytesPtr);
      } else {
        IC.isar_key_add_byte_list_hash(keyPtr, nullptr, 0);
      }
      break;
    case NativeIndexType.boolListHash:
      if (value is List<bool?>) {
        final boolListPtr = malloc<Uint8>(value.length);
        boolListPtr.asTypedList(value.length).setAll(0, value.map(boolToByte));
        IC.isar_key_add_byte_list_hash(keyPtr, boolListPtr, value.length);
        malloc.free(boolListPtr);
      } else {
        IC.isar_key_add_byte_list_hash(keyPtr, nullptr, 0);
      }
      break;
    case NativeIndexType.intListHash:
      if (value is List<int?>) {
        final intListPtr = malloc<Int32>(value.length);
        intListPtr
            .asTypedList(value.length)
            .setAll(0, value.map((e) => e ?? nullInt));
        IC.isar_key_add_int_list_hash(keyPtr, intListPtr, value.length);
        malloc.free(intListPtr);
      } else {
        IC.isar_key_add_int_list_hash(keyPtr, nullptr, 0);
      }
      break;
    case NativeIndexType.longListHash:
      if (value is List<int?>) {
        final longListPtr = malloc<Int64>(value.length);
        longListPtr
            .asTypedList(value.length)
            .setAll(0, value.map((e) => e ?? nullLong));
        IC.isar_key_add_long_list_hash(keyPtr, longListPtr, value.length);
        malloc.free(longListPtr);
      } else {
        IC.isar_key_add_long_list_hash(keyPtr, nullptr, 0);
      }
      break;
    case NativeIndexType.stringListHash:
    case NativeIndexType.stringListHashCIS:
      if (value is List<String?>) {
        final stringListPtr = malloc<Pointer<Int8>>(value.length);
        for (var i = 0; i < value.length; i++) {
          stringListPtr[i] = _strToNative(value[i]);
        }
        IC.isar_key_add_string_list_hash(keyPtr, stringListPtr, value.length,
            type == NativeIndexType.stringListHash);
        for (var i = 0; i < value.length; i++) {
          _freeStr(stringListPtr[i]);
        }
      } else {
        IC.isar_key_add_string_list_hash(keyPtr, nullptr, 0, false);
      }
      break;
  }
}

Pointer<Int8> _strToNative(String? str) {
  if (str == null) {
    return Pointer.fromAddress(0);
  } else {
    return str.toNativeUtf8().cast();
  }
}

void _freeStr(Pointer<Int8> strPtr) {
  if (!strPtr.isNull) {
    malloc.free(strPtr);
  }
}
