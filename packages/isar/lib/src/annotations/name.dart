part of '../../isar.dart';

/// {@template isar_name}
/// Annotate Isar collections or properties to change their name.
///
/// Can be used to change the name in Dart independently of Isar.
/// {@endtemplate}
@Target({TargetKind.classType, TargetKind.field, TargetKind.getter})
class Name {
  /// {@macro isar_name}
  const Name(this.name);

  /// The name this entity should have in the database.
  final String name;
}
