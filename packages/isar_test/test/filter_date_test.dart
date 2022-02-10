import 'package:isar/isar.dart';
import 'package:isar_test/common.dart';

part 'filter_date_test.g.dart';

@Collection()
class DateTimeModel {
  @Id()
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
          listEquals(list, other.list) &&
          listEquals(listNullable, other.listNullable) &&
          listEquals(listElementNullable, other.listElementNullable) &&
          listEquals(
              listNullableElementNullable, other.listNullableElementNullable);
    }
    return false;
  }
}

void main() {}
