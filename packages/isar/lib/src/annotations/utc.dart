part of '../../isar.dart';

/// {@template isar_utc}
/// By default Isar returns [DateTime] values in the local timezone. If you want
/// to receive UTC [DateTime] values instead, annotate the property or accessor
/// with `@utc`.
/// {@endtemplate}
const utc = Utc();

/// {@macro isar_utc}
@Target({TargetKind.field, TargetKind.getter})
class Utc {
  /// {@macro isar_utc}
  const Utc();
}
