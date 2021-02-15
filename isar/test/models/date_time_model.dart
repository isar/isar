import 'package:isar/isar.dart';

import '../isar.g.dart';
import 'package:isar_annotation/isar_annotation.dart';

@Collection()
class DateTimeModel {
  @ObjectId()
  int? id;

  @Index()
  late DateTime date;

  @Index()
  DateTime? dateNullable;

  late List<DateTime> list;

  List<DateTime>? listNullable;

  late List<DateTime?> listElementNullable;

  List<DateTime?>? listNullableElementNullable;

  DateTimeModel();

  @override
  bool operator ==(other) {
    if (other is DateTimeModel) {
      return other.date == date &&
          other.dateNullable == dateNullable &&
          other.list == list &&
          other.listNullable == listNullable &&
          other.listElementNullable == listElementNullable &&
          other.listNullableElementNullable == listNullableElementNullable;
    }
    return false;
  }
}
