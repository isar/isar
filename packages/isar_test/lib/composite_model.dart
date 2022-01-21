import 'package:isar/isar.dart';

part 'composite_model.g.dart';

@Collection()
class CompositeModel {
  int? id;

  @Index(
    composite: [CompositeIndex('stringValue')],
  )
  int? intValue;

  @Index(
    composite: [
      CompositeIndex(
        'stringValue2',
        type: IndexType.value,
      )
    ],
    unique: true,
  )
  String? stringValue;

  String? stringValue2;

  @override
  String toString() {
    return '{id: $id, intValue: $intValue, stringValue: $stringValue, stringValue2: $stringValue2}';
  }

  @override
  bool operator ==(other) {
    return (other is CompositeModel) &&
        other.id == id &&
        other.intValue == intValue &&
        other.stringValue == stringValue &&
        other.stringValue2 == stringValue2;
  }
}
