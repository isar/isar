part of '../../isar.dart';

/// {@template isar_id}
/// Annotate the property or accessor in an Isar collection that should be used
/// as the primary key.
/// {@endtemplate}
const id = Id();

/// {@macro isar_id}
@Target({TargetKind.field, TargetKind.getter})
class Id {
  /// {@macro isar_id}
  const Id();
}
