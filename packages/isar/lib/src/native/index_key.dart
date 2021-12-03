part of isar_native;

final _keyPtrPtr = malloc<Pointer>();

Pointer<NativeType> buildIndexKey(
    IsarCollectionImpl col, String indexProperty, List<dynamic> values) {
  final indexId = col.indexIds[indexProperty];
  if (indexId == null) {
    throw 'Unknown index property $indexProperty';
  }

  final types = col.indexTypes[indexProperty]!;
  if (values.length > types.length) {
    throw 'Invalid values for index $indexProperty';
  }

  nCall(IC.isar_key_create(col.ptr, _keyPtrPtr, indexId));
  final keyPtr = _keyPtrPtr.value;

  for (var i = 0; i < values.length; i++) {
    _addKeyValue(keyPtr, values[i], types[i]);
  }

  return keyPtr;
}

Pointer<NativeType> buildLowerUnboundedIndexKey(
    IsarCollectionImpl col, String indexProperty) {
  final indexId = col.indexIds[indexProperty];
  if (indexId == null) {
    throw 'Unknown index property $indexProperty';
  }
  nCall(IC.isar_key_create(col.ptr, _keyPtrPtr, indexId));
  return _keyPtrPtr.value;
}

Pointer<NativeType> buildUpperUnboundedIndexKey(
    IsarCollectionImpl col, String indexProperty) {
  final indexId = col.indexIds[indexProperty];
  if (indexId == null) {
    throw 'Unknown index property $indexProperty';
  }
  nCall(IC.isar_key_create(col.ptr, _keyPtrPtr, indexId));
  final keyPtr = _keyPtrPtr.value;
  IC.isar_key_add_byte(keyPtr, 255);

  return keyPtr;
}

void _addKeyValue(
    Pointer<NativeType> keyPtr, dynamic value, NativeIndexType type) {
  switch (type) {
    case NativeIndexType.Bool:
      if (value is bool?) {
        IC.isar_key_add_byte(keyPtr, boolToByte(value));
        return;
      }
      break;
    case NativeIndexType.Int:
      if (value is int?) {
        IC.isar_key_add_int(keyPtr, value ?? nullInt);
        return;
      }
      break;
    case NativeIndexType.Float:
      if (value is double?) {
        IC.isar_key_add_float(keyPtr, value ?? nullFloat);
        return;
      }
      break;
    case NativeIndexType.Long:
      if (value is int?) {
        IC.isar_key_add_long(keyPtr, value ?? nullLong);
        return;
      }
      break;
    case NativeIndexType.Double:
      if (value is double?) {
        IC.isar_key_add_double(keyPtr, value ?? nullDouble);
        return;
      }
      break;
    case NativeIndexType.StringHash:
    case NativeIndexType.StringHashCIS:
      if (value is String?) {
        final strPtr = _strToNative(value);
        IC.isar_key_add_string_hash(
            keyPtr, strPtr, type == NativeIndexType.StringHash);
        _freeStr(strPtr);
        return;
      }
      break;
    case NativeIndexType.StringValue:
    case NativeIndexType.StringValueCIS:
      if (value is String?) {
        final strPtr = _strToNative(value);
        IC.isar_key_add_string_value(
            keyPtr, strPtr, type == NativeIndexType.StringValue);
        _freeStr(strPtr);
        return;
      }
      break;
    case NativeIndexType.StringWords:
    case NativeIndexType.StringWordsCIS:
      if (value is String?) {
        if (value == null) {
          throw 'Null words are unsupported';
        }
        final strPtr = _strToNative(value);
        IC.isar_key_add_string_word(
            keyPtr, strPtr, type == NativeIndexType.StringWords);
        _freeStr(strPtr);
        return;
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
