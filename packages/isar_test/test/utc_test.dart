import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'utc_test.g.dart';

@collection
class DateModel {
  DateModel(this.id, this.date, this.dateUtc);

  int id;

  DateTime date;

  @utc
  DateTime dateUtc;
}

void main() {
  group('UTC', () {
    late Isar isar;
    late IsarCollection<int, DateModel> col;

    setUp(() async {
      isar = await openTempIsar([DateModelSchema]);
      col = isar.dateModels;
    });

    isarTest('get', () {
      final date = DateTime.now();

      isar.write((isar) {
        col.put(DateModel(1, date, date));
        col.put(DateModel(2, date.toUtc(), date.toUtc()));
      });

      expect(col.get(1)!.date, date);
      expect(col.get(1)!.dateUtc, date.toUtc());
      expect(col.get(2)!.date, date);
      expect(col.get(2)!.dateUtc, date.toUtc());
    });

    isarTest('get property', () {
      final date = DateTime.now();

      isar.write((isar) {
        col.put(DateModel(1, date, date));
        col.put(DateModel(2, date.toUtc(), date.toUtc()));
      });

      expect(col.where().dateProperty().findAll(), [date, date]);
      expect(
        col.where().dateUtcProperty().findAll(),
        [date.toUtc(), date.toUtc()],
      );
    });
  });
}
