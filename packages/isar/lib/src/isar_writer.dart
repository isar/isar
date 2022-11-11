// ignore_for_file: public_member_api_docs

part of isar;

/// @nodoc
@protected
abstract class IsarWriter {
  void writeBool(int offset, bool? value);

  void writeByte(int offset, int value);

  void writeInt(int offset, int? value);

  void writeFloat(int offset, double? value);

  void writeLong(int offset, int? value);

  void writeDouble(int offset, double? value);

  void writeDateTime(int offset, DateTime? value);

  void writeString(int offset, String? value);

  void writeObject<T>(
    int offset,
    Map<Type, List<int>> allOffsets,
    Serialize<T> serialize,
    T? value,
  );

  void writeByteList(int offset, List<int>? values);

  void writeBoolList(int offset, List<bool?>? values);

  void writeIntList(int offset, List<int?>? values);

  void writeFloatList(int offset, List<double?>? values);

  void writeLongList(int offset, List<int?>? values);

  void writeDoubleList(int offset, List<double?>? values);

  void writeDateTimeList(int offset, List<DateTime?>? values);

  void writeStringList(int offset, List<String?>? values);

  void writeObjectList<T>(
    int offset,
    Map<Type, List<int>> allOffsets,
    Serialize<T> serialize,
    List<T?>? values,
  );
}
