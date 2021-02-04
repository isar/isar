import 'package:isar/isar.dart';

@Collection()
class Message {
  int? id;

  @Index()
  String? message;

  @override
  bool operator ==(dynamic other) {
    if (other is Message) {
      return other.id == id && other.message == message;
    } else {
      return false;
    }
  }
}
