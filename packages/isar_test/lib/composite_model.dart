
/*@Collection()
class CompositeModel {
  int? id;

  @Index(composite: [
    CompositeIndex('stringValue'),
    CompositeIndex('stringValue2'),
  ])
  int? intValue;

  @Index(composite: [
    CompositeIndex('stringValue2'),
    CompositeIndex('intValue'),
  ])
  String? stringValue;

  @Index(composite: [CompositeIndex('intValue')])
  String? stringValue2;

  @Index(composite: [CompositeIndex('intValue')])
  double? doubleValue;
}*/
