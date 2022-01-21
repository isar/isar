part of isar;

/// Annotation to specify the id accessor of a collection.
///
/// If the accessor is called `id`, this annotation can be omitted.
@Target({TargetKind.field, TargetKind.getter})
class Id {
  /// Annotation to specify the id accessor of a collection.
  const Id();
}
