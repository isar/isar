import 'package:isar/isar.dart';
import 'package:js/js_util.dart';
import 'package:meta/dart2js.dart';

class IsarReaderImpl implements IsarReader {
  IsarReaderImpl(this.object);

  final Object object;

  @tryInline
  @override
  bool readBool(int offset) {
    final value = getProperty<dynamic>(object, offset);
    return value == 1;
  }

  @tryInline
  @override
  bool? readBoolOrNull(int offset) {
    final value = getProperty<dynamic>(object, offset);
    return value == 0
        ? false
        : value == 1
            ? true
            : null;
  }

  @tryInline
  @override
  int readByte(int offset) {
    final value = getProperty<dynamic>(object, offset);
    return value is int ? value : 0;
  }

  @tryInline
  @override
  int? readByteOrNull(int offset) {
    final value = getProperty<dynamic>(object, offset);
    return value is int ? value : null;
  }

  @tryInline
  @override
  int readInt(int offset) {
    final value = getProperty<dynamic>(object, offset);
    return value is int ? value : 0;
  }

  @tryInline
  @override
  int? readIntOrNull(int offset) {
    final value = getProperty<dynamic>(object, offset);
    return value is int ? value : null;
  }

  @tryInline
  @override
  double readFloat(int offset) {
    final value = getProperty<dynamic>(object, offset);
    return value is double ? value : 0;
  }

  @tryInline
  @override
  double? readFloatOrNull(int offset) {
    final value = getProperty<dynamic>(object, offset);
    return value is double ? value : null;
  }

  @tryInline
  @override
  int readLong(int offset) {
    final value = getProperty<dynamic>(object, offset);
    return value is int ? value : 0;
  }

  @tryInline
  @override
  int? readLongOrNull(int offset) {
    final value = getProperty<dynamic>(object, offset);
    return value is int ? value : null;
  }

  @tryInline
  @override
  double readDouble(int offset) {
    final value = getProperty<dynamic>(object, offset);
    return value is double ? value : 0;
  }

  @tryInline
  @override
  double? readDoubleOrNull(int offset) {
    final value = getProperty<dynamic>(object, offset);
    return value is double ? value : null;
  }

  @tryInline
  @override
  DateTime readDateTime(int offset) {
    final value = getProperty<dynamic>(object, offset);
    return value is int
        ? DateTime.fromMillisecondsSinceEpoch(value, isUtc: true).toLocal()
        : DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
  }

  @override
  DateTime? readDateTimeOrNull(int offset);

  @override
  String readString(int offset);

  @override
  String? readStringOrNull(int offset);

  @override
  T? readObjectOrNull<T>(
    int offset,
    Deserialize<T> deserialize,
    Map<Type, List<int>> allOffsets,
  );

  @override
  List<bool>? readBoolList(int offset);

  @override
  List<bool?>? readBoolOrNullList(int offset);

  @override
  List<int>? readByteList(int offset);

  @override
  List<int>? readIntList(int offset);

  @override
  List<int?>? readIntOrNullList(int offset);

  @override
  List<double>? readFloatList(int offset);

  @override
  List<double?>? readFloatOrNullList(int offset);

  @override
  List<int>? readLongList(int offset);

  @override
  List<int?>? readLongOrNullList(int offset);

  @override
  List<double>? readDoubleList(int offset);

  @override
  List<double?>? readDoubleOrNullList(int offset);

  @override
  List<DateTime>? readDateTimeList(int offset);

  @override
  List<DateTime?>? readDateTimeOrNullList(int offset);

  @override
  List<String>? readStringList(int offset);

  @override
  List<String?>? readStringOrNullList(int offset);

  @override
  List<T>? readObjectList<T>(
    int offset,
    Deserialize<T> deserialize,
    Map<Type, List<int>> allOffsets,
    T defaultValue,
  );

  @override
  List<T?>? readObjectOrNullList<T>(
    int offset,
    Deserialize<T> deserialize,
    Map<Type, List<int>> allOffsets,
  );
}
