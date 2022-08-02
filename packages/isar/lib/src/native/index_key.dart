// ignore_for_file: public_member_api_docs

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:isar/isar.dart';
import 'package:isar/src/native/binary_writer.dart';
import 'package:isar/src/native/bindings.dart';
import 'package:isar/src/native/encode_string.dart';
import 'package:isar/src/native/isar_core.dart';

final _keyPtrPtr = malloc<Pointer<CIndexKey>>();

Pointer<CIndexKey>? buildIndexKey(
  CollectionSchema<dynamic> schema,
  String indexName,
  IndexKey key, {
  bool addMaxComposite = false,
  bool requireFullKey = false,
  bool increase = false,
  bool decrease = false,
}) {
  final index = schema.index(indexName);
  if (key.length > index.properties.length ||
      (requireFullKey && key.length != index.properties.length)) {
    throw IsarError('Invalid values for index $indexName.');
  }

  IC.isar_key_create(_keyPtrPtr);
  final keyPtr = _keyPtrPtr.value;

  for (var i = 0; i < key.length; i++) {
    final indexProperty = index.properties[i];
    _addKeyValue(
      keyPtr,
      key[i],
      schema.property(indexProperty.name),
      indexProperty.type,
      indexProperty.caseSensitive,
    );
  }

  if (increase) {
    if (!IC.isar_key_increase(keyPtr)) {
      return null;
    }
  }

  if (decrease) {
    if (!IC.isar_key_decrease(keyPtr)) {
      return null;
    }
  }

  // Also include composite indexes for upper keys
  if (addMaxComposite && index.properties.length > key.length) {
    IC.isar_key_add_long(keyPtr, maxLong);
  }

  return keyPtr;
}

Pointer<CIndexKey> buildLowerUnboundedIndexKey() {
  IC.isar_key_create(_keyPtrPtr);
  return _keyPtrPtr.value;
}

Pointer<CIndexKey> buildUpperUnboundedIndexKey() {
  IC.isar_key_create(_keyPtrPtr);
  final keyPtr = _keyPtrPtr.value;
  IC.isar_key_add_long(keyPtr, maxLong);

  return keyPtr;
}

void _addKeyValue(
  Pointer<CIndexKey> keyPtr,
  Object? value,
  PropertySchema property,
  IndexType type,
  bool caseSensitive,
) {
  if (value is DateTime) {
    value = value.toUtc().microsecondsSinceEpoch;
  } else if (value is List<DateTime?>) {
    value = value.map((e) => e?.toUtc().microsecondsSinceEpoch);
  }

  switch (property.type) {
    case IsarType.bool:
      IC.isar_key_add_byte(keyPtr, (value as bool?).byteValue);
      break;
    case IsarType.byte:
      IC.isar_key_add_byte(keyPtr, value! as int);
      break;
    case IsarType.int:
      IC.isar_key_add_int(keyPtr, (value as int?) ?? nullInt);
      break;
    case IsarType.float:
      IC.isar_key_add_float(keyPtr, (value as double?) ?? nullFloat);
      break;
    case IsarType.long:
      IC.isar_key_add_long(keyPtr, (value as int?) ?? nullLong);
      break;
    case IsarType.double:
      IC.isar_key_add_double(keyPtr, (value as double?) ?? nullDouble);
      break;
    case IsarType.dateTime:
      IC.isar_key_add_long(keyPtr, (value as DateTime?).longValue);
      break;
    case IsarType.enumeration:
      IC.isar_key_add_byte(keyPtr, (value as Enum?).byteValue);
      break;
    case IsarType.string:
      final strPtr = _strToNative(value as String?);
      if (type == IndexType.hash) {
        IC.isar_key_add_string_hash(keyPtr, strPtr, caseSensitive);
      } else {
        IC.isar_key_add_string(keyPtr, strPtr, caseSensitive);
      }
      _freeStr(strPtr);
      break;
    case IsarType.boolList:
      if (value == null) {
        IC.isar_key_add_byte_list_hash(keyPtr, nullptr, 0);
      } else {
        value as List<bool?>;
        final boolListPtr = malloc<Uint8>(value.length);
        boolListPtr
            .asTypedList(value.length)
            .setAll(0, value.map((e) => e.byteValue));
        IC.isar_key_add_byte_list_hash(keyPtr, boolListPtr, value.length);
        malloc.free(boolListPtr);
      }
      break;
    case IsarType.byteList:
      if (value == null) {
        IC.isar_key_add_byte_list_hash(keyPtr, nullptr, 0);
      } else {
        value as List<int>;
        final bytesPtr = malloc<Uint8>(value.length);
        bytesPtr.asTypedList(value.length).setAll(0, value);
        IC.isar_key_add_byte_list_hash(keyPtr, bytesPtr, value.length);
        malloc.free(bytesPtr);
      }
      break;
    case IsarType.intList:
      if (value == null) {
        IC.isar_key_add_int_list_hash(keyPtr, nullptr, 0);
      } else {
        value as List<int?>;
        final intListPtr = malloc<Int32>(value.length);
        intListPtr
            .asTypedList(value.length)
            .setAll(0, value.map((e) => e ?? nullInt));
        IC.isar_key_add_int_list_hash(keyPtr, intListPtr, value.length);
        malloc.free(intListPtr);
      }
      break;
    case IsarType.longList:
      if (value == null) {
        IC.isar_key_add_long_list_hash(keyPtr, nullptr, 0);
      } else {
        value as List<int?>;
        final longListPtr = malloc<Int64>(value.length);
        longListPtr
            .asTypedList(value.length)
            .setAll(0, value.map((e) => e ?? nullLong));
        IC.isar_key_add_long_list_hash(keyPtr, longListPtr, value.length);
        malloc.free(longListPtr);
      }
      break;
    case IsarType.dateTimeList:
      if (value == null) {
        IC.isar_key_add_long_list_hash(keyPtr, nullptr, 0);
      } else {
        value as List<DateTime?>;
        final longListPtr = malloc<Int64>(value.length);
        for (var i = 0; i < value.length; i++) {
          longListPtr[i] = value[i].longValue;
        }
        IC.isar_key_add_long_list_hash(keyPtr, longListPtr, value.length);
      }
      break;
    case IsarType.enumerationList:
      if (value == null) {
        IC.isar_key_add_long_list_hash(keyPtr, nullptr, 0);
      } else {
        value as List<Enum?>;
        final byteListPtr = malloc<Uint8>(value.length);
        for (var i = 0; i < value.length; i++) {
          byteListPtr[i] = value[i].byteValue;
        }
        IC.isar_key_add_byte_list_hash(keyPtr, byteListPtr, value.length);
      }
      break;
    case IsarType.stringList:
      if (value == null) {
        IC.isar_key_add_string_list_hash(keyPtr, nullptr, 0, false);
      } else {
        value as List<String?>;
        final stringListPtr = malloc<Pointer<Char>>(value.length);
        for (var i = 0; i < value.length; i++) {
          stringListPtr[i] = _strToNative(value[i]);
        }
        IC.isar_key_add_string_list_hash(
          keyPtr,
          stringListPtr,
          value.length,
          caseSensitive,
        );
        for (var i = 0; i < value.length; i++) {
          _freeStr(stringListPtr[i]);
        }
      }
      break;
    case IsarType.id:
    case IsarType.object:
    case IsarType.floatList:
    case IsarType.doubleList:
    case IsarType.objectList:
      throw IsarError('Unsupported property type.');
  }
}

Pointer<Char> _strToNative(String? str) {
  if (str == null) {
    return Pointer.fromAddress(0);
  } else {
    return str.toCString(malloc);
  }
}

void _freeStr(Pointer<Char> strPtr) {
  if (!strPtr.isNull) {
    malloc.free(strPtr);
  }
}
