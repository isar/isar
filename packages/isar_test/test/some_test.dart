import 'dart:convert';

import 'package:isar/isar.dart';

import 'common.dart';

part 'some_test.g.dart';

@Collection()
class Student {
  Student({
    this.sid,
    this.name,
    this.teacher,
  });

  @Id()
  int? sid;

  String? name;

  @TeacherTypeConverter()
  Teacher? teacher;

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        sid: json["sid"],
        name: json["name"],
        teacher: Teacher.fromJson(json["teacher"]),
      );

  Map<String, dynamic> toJson() => {
        "sid": sid,
        "name": name,
        "teacher": teacher?.toJson(),
      };
}

@Collection()
class Teacher {
  Teacher({
    this.tid,
    this.name,
  });

  @Id()
  int? tid;

  String? name;

  factory Teacher.fromJson(Map<String, dynamic> json) => Teacher(
        tid: json["tid"],
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        "tid": tid,
        "name": name,
      };
}

class TeacherTypeConverter extends TypeConverter<Teacher?, String> {
  const TeacherTypeConverter();

  @override
  Teacher fromIsar(String object) {
    return Teacher.fromJson(json.decode(object));
  }

  @override
  String toIsar(Teacher? object) {
    return object == null ? '' : jsonEncode(object.toJson());
  }
}

void main() async {
  final isar = await openTempIsar([StudentSchema]);
  await isar.writeTxn((isar) {
    return isar.students.putAll([
      Student(sid: 1, name: 's', teacher: Teacher(tid: 4, name: 'hello')),
    ]);
  });

  print(isar.students.where().findAllSync().map((e) => e.toJson()));
}
