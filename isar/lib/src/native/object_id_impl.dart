part of isar_native;

class ObjectIdImpl extends ObjectId {
  @override
  final int time;

  final int randCounter;

  const ObjectIdImpl(this.time, this.randCounter);
}
