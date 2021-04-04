import 'package:isar/isar.dart';

@Collection()
class StringModel {
  @Id()
  int? id;

  @Index(indexType: IndexType.hash)
  String? hashField = '';

  @Index(indexType: IndexType.value)
  String? valueField = '';

  @Index(indexType: IndexType.words)
  String? wordsField = '';

  @override
  String toString() {
    return '{valueField: $valueField, hashField: $hashField, wordsField: $wordsField}';
  }

  StringModel();

  StringModel.init(String? value)
      : hashField = value,
        valueField = value,
        wordsField = value;

  @override
  bool operator ==(other) {
    if (other is StringModel) {
      return hashField == other.hashField &&
          valueField == other.valueField &&
          wordsField == other.wordsField;
    }
    return false;
  }
}
