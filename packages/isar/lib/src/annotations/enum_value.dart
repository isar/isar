part of '../../isar.dart';

/// {@template isar_enum_value}
/// Annotation to specify how an enum property should be serialized.
/// {@endtemplate}
const enumValue = EnumValue();

/// {@macro isar_enum_value}
@Target({TargetKind.field, TargetKind.getter})
class EnumValue {
  /// {@macro isar_enum_value}
  const EnumValue();
}
