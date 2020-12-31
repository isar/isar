part of isar_web;

class ObjectIdImpl extends ObjectId {
  @override
  final int time;

  final int randCounter1;

  final int randCounter2;

  const ObjectIdImpl(this.time, this.randCounter1, this.randCounter2);
}
