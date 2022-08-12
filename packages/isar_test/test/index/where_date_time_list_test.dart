import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';

part 'where_date_time_list_test.g.dart';

@Collection()
class DateTimeModel {
  DateTimeModel(this.list) : hashList = list;
  Id? id;

  @Index(type: IndexType.value)
  List<DateTime?>? list;

  @Index(type: IndexType.hash)
  List<DateTime?>? hashList;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is DateTimeModel &&
      listEquals(
        list?.map((e) => e?.toUtc()).toList(),
        other.list?.map((e) => e?.toUtc()).toList(),
      ) &&
      listEquals(
        hashList?.map((e) => e?.toUtc()).toList(),
        other.hashList?.map((e) => e?.toUtc()).toList(),
      );
}

DateTime local(int year, [int month = 1, int day = 1]) {
  return DateTime(year, month, day);
}

DateTime utc(int year, [int month = 1, int day = 1]) {
  return local(year, month, day).toUtc();
}

void main() {
  group('Where DateTime list', () {
    late Isar isar;
    late IsarCollection<DateTimeModel> col;

    late DateTimeModel obj1;
    late DateTimeModel obj2;
    late DateTimeModel obj3;
    late DateTimeModel obj4;
    late DateTimeModel obj5;
    late DateTimeModel objNull;

    setUp(() async {
      isar = await openTempIsar([DateTimeModelSchema]);
      col = isar.dateTimeModels;
    });

    tearDown(() => isar.close(deleteFromDisk: true));

    //TODO
  });
}
