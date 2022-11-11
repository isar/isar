// ignore_for_file: public_member_api_docs

part of isar;

/// @nodoc
@protected
abstract class IsarReader {
  bool readBool(int offset);

  bool? readBoolOrNull(int offset);

  int readByte(int offset);

  int? readByteOrNull(int offset);

  int readInt(int offset);

  int? readIntOrNull(int offset);

  double readFloat(int offset);

  double? readFloatOrNull(int offset);

  int readLong(int offset);

  int? readLongOrNull(int offset);

  double readDouble(int offset);

  double? readDoubleOrNull(int offset);

  DateTime readDateTime(int offset);

  DateTime? readDateTimeOrNull(int offset);

  String readString(int offset);

  String? readStringOrNull(int offset);

  T? readObjectOrNull<T>(
    int offset,
    Deserialize<T> deserialize,
    Map<Type, List<int>> allOffsets,
  );

  List<bool>? readBoolList(int offset);

  List<bool?>? readBoolOrNullList(int offset);

  List<int>? readByteList(int offset);

  List<int>? readIntList(int offset);

  List<int?>? readIntOrNullList(int offset);

  List<double>? readFloatList(int offset);

  List<double?>? readFloatOrNullList(int offset);

  List<int>? readLongList(int offset);

  List<int?>? readLongOrNullList(int offset);

  List<double>? readDoubleList(int offset);

  List<double?>? readDoubleOrNullList(int offset);

  List<DateTime>? readDateTimeList(int offset);

  List<DateTime?>? readDateTimeOrNullList(int offset);

  List<String>? readStringList(int offset);

  List<String?>? readStringOrNullList(int offset);

  List<T>? readObjectList<T>(
    int offset,
    Deserialize<T> deserialize,
    Map<Type, List<int>> allOffsets,
    T defaultValue,
  );

  List<T?>? readObjectOrNullList<T>(
    int offset,
    Deserialize<T> deserialize,
    Map<Type, List<int>> allOffsets,
  );
}
