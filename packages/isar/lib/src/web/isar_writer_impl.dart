// ignore_for_file: public_member_api_docs

import 'package:isar/isar.dart';
import 'package:isar/src/web/isar_reader_impl.dart';
import 'package:meta/dart2js.dart';

T newObject<T>() => <Object, dynamic>{} as T;

void setProperty(Object object, Object key, Object? value) {
  (object as Map<Object, dynamic>)[key] = value;
}

class IsarWriterImpl implements IsarWriter {
  IsarWriterImpl(this.object);

  final Object object;

  @tryInline
  @override
  void writeBool(int offset, bool? value) {
    final number = value == true
        ? 1
        : value == false
            ? 0
            : null;
    setProperty(object, offset, number);
  }

  @tryInline
  @override
  void writeByte(int offset, int value) {
    setProperty(object, offset, value);
  }

  @tryInline
  @override
  void writeInt(int offset, int? value) {
    setProperty(object, offset, value);
  }

  @tryInline
  @override
  void writeFloat(int offset, double? value) {
    setProperty(object, offset, value);
  }

  @tryInline
  @override
  void writeLong(int offset, int? value) {
    setProperty(object, offset, value);
  }

  @tryInline
  @override
  void writeDouble(int offset, double? value) {
    setProperty(object, offset, value);
  }

  @tryInline
  @override
  void writeDateTime(int offset, DateTime? value) {
    setProperty(
      object,
      offset,
      value?.toUtc().microsecondsSinceEpoch,
    );
  }

  @tryInline
  @override
  void writeString(int offset, String? value) {
    setProperty(object, offset, value);
  }

  @tryInline
  @override
  void writeObject<T>(
    int offset,
    Map<Type, List<int>> allOffsets,
    Serialize<T> serialize,
    T? value,
  ) {
    if (value != null) {
      final object = newObject<Object>();
      final writer = IsarWriterImpl(object);
      serialize(value, writer, allOffsets[T]!, allOffsets);
      setProperty(this.object, offset, object);
    }
  }

  @tryInline
  @override
  void writeByteList(int offset, List<int>? values) {
    setProperty(object, offset, values);
  }

  @tryInline
  @override
  void writeBoolList(int offset, List<bool?>? values) {
    final list = values
        ?.map(
          (e) => e == false
              ? 0
              : e == true
                  ? 1
                  : null,
        )
        .toList();
    setProperty(object, offset, list);
  }

  @tryInline
  @override
  void writeIntList(int offset, List<int?>? values) {
    final list = values?.toList();
    setProperty(object, offset, list);
  }

  @tryInline
  @override
  void writeFloatList(int offset, List<double?>? values) {
    final list = values?.toList();
    setProperty(object, offset, list);
  }

  @tryInline
  @override
  void writeLongList(int offset, List<int?>? values) {
    final list = values?.toList();
    setProperty(object, offset, list);
  }

  @tryInline
  @override
  void writeDoubleList(int offset, List<double?>? values) {
    final list = values?.toList();
    setProperty(object, offset, list);
  }

  @tryInline
  @override
  void writeDateTimeList(int offset, List<DateTime?>? values) {
    final list = values?.map((e) => e?.toUtc().microsecondsSinceEpoch).toList();
    setProperty(object, offset, list);
  }

  @tryInline
  @override
  void writeStringList(int offset, List<String?>? values) {
    final list = values?.toList();
    setProperty(object, offset, list);
  }

  @tryInline
  @override
  void writeObjectList<T>(
    int offset,
    Map<Type, List<int>> allOffsets,
    Serialize<T> serialize,
    List<T?>? values,
  ) {
    if (values != null) {
      final list = values.map((e) {
        if (e != null) {
          final object = newObject<Object>();
          final writer = IsarWriterImpl(object);
          serialize(e, writer, allOffsets[T]!, allOffsets);
          return object;
        }
      }).toList();
      setProperty(object, offset, list);
    }
  }
}
