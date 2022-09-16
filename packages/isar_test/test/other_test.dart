import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

void main() {
  group('Other', () {
    isarTestVm('split words', () {
      expect(Isar.splitWords(''), <String>[]);
      expect(Isar.splitWords('single'), ['single']);
      expect(
          Isar.splitWords(
            'The quick (“brown”) fox can’t jump 32.3 feet, right?',
          ),
          [
            'The',
            'quick',
            'brown',
            'fox',
            'can’t',
            'jump',
            '32.3',
            'feet',
            'right'
          ]);
      expect(
        Isar.splitWords('איך בלש תפס גמד רוצח עז קטנה?'),
        ['איך', 'בלש', 'תפס', 'גמד', 'רוצח', 'עז', 'קטנה'],
      );
      expect(
          Isar.splitWords(
            'В чащах юга жил бы цитрус? Да, но фальшивый экземпляр!',
          ),
          [
            'В',
            'чащах',
            'юга',
            'жил',
            'бы',
            'цитрус',
            'Да',
            'но',
            'фальшивый',
            'экземпляр'
          ]);
    });
  });
}
