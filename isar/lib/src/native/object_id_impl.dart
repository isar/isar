import 'package:isar/src/object_id.dart';

class ObjectIdImpl extends ObjectId {
  @override
  final int time;

  final int randCounter;

  const ObjectIdImpl(this.time, this.randCounter);
}
