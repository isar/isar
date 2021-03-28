import 'package:isar/isar.dart';

import '../isar.g.dart';

@Collection()
class StringModelCIS {
  @Id()
  int? id;

  @Index(indexType: IndexType.hash, caseSensitive: false)
  String? hashField = '';

  @Index(indexType: IndexType.value, caseSensitive: false)
  String? valueField = '';

  @Index(indexType: IndexType.words, caseSensitive: false)
  String? wordsField = '';

  @override
  String toString() {
    return '{field: $valueField, field: $hashField, field: $wordsField}';
  }

  StringModelCIS();

  StringModelCIS.init(String? value)
      : hashField = value,
        valueField = value,
        wordsField = value;

  @override
  bool operator ==(other) {
    if (other is StringModelCIS) {
      return hashField?.toLowerCase() == other.hashField?.toLowerCase() &&
          valueField?.toLowerCase() == other.valueField?.toLowerCase() &&
          wordsField?.toLowerCase() == other.wordsField?.toLowerCase();
    }
    return false;
  }
}
