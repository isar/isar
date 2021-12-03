import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:isar/isar.dart';

part 'freezed_model.freezed.dart';

@freezed
@Collection()
class FreezedModel with _$FreezedModel {
  const factory FreezedModel({int? id, required String name}) = MyFreezedModel;
}
