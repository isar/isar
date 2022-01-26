import 'package:isar/isar.dart';

part 'message_model.g.dart';

@Collection()
class Message {
  int? id;

  @Index()
  String? message;

  @override
  String toString() {
    return '{id: $id, message: $message}';
  }

  @override
  bool operator ==(dynamic other) {
    if (other is Message) {
      return other.message == message;
    } else {
      return false;
    }
  }
}
