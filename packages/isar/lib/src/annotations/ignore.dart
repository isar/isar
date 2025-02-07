part of '../../isar.dart';

/// {@template isar_ignore}
/// Annotate a property or accessor in an Isar collection to ignore it.
/// {@endtemplate}
const ignore = Ignore();

/// {@macro isar_ignore}
@Target({TargetKind.field, TargetKind.getter})
class Ignore {
  /// {@macro isar_ignore}
  const Ignore();
}
