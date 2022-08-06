part of isar;

/// This schema represents a link to the same or another collection.
class LinkSchema {
  /// @nodoc
  @protected
  const LinkSchema({
    required this.id,
    required this.name,
    required this.target,
    required this.isSingle,
    this.linkName,
  });

  /// Internal id of this link.
  final int id;

  /// Name of this link.
  final String name;

  /// Isar name of the target collection.
  final String target;

  /// Whether this is link can only hold a single target object.
  final bool isSingle;

  /// If this is a backlink, [linkName] is the name of the source link in the
  /// [target] collection.
  final String? linkName;

  /// Whether this link is a backlink.
  bool get isBacklink => linkName != null;

  /// @nodoc
  @protected
  Map<String, dynamic> toSchemaJson() {
    return {
      'name': name,
      'target': target,
      'single': isSingle,
    };
  }
}
