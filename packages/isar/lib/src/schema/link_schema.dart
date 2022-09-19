part of isar;

/// This schema represents a link to the same or another collection.
class LinkSchema {
  /// @nodoc
  @protected
  const LinkSchema({
    required this.id,
    required this.name,
    required this.target,
    required this.single,
    this.linkName,
  });

  /// @nodoc
  @protected
  factory LinkSchema.fromJson(Map<String, dynamic> json) {
    return LinkSchema(
      id: -1,
      name: json['name'] as String,
      target: json['target'] as String,
      single: json['single'] as bool,
      linkName: json['linkName'] as String?,
    );
  }

  /// Internal id of this link.
  final int id;

  /// Name of this link.
  final String name;

  /// Isar name of the target collection.
  final String target;

  /// Whether this is link can only hold a single target object.
  final bool single;

  /// If this is a backlink, [linkName] is the name of the source link in the
  /// [target] collection.
  final String? linkName;

  /// Whether this link is a backlink.
  bool get isBacklink => linkName != null;

  /// @nodoc
  @protected
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
      'target': target,
      'single': single,
    };

    assert(() {
      if (linkName != null) {
        json['linkName'] = linkName;
      }
      return true;
    }());

    return json;
  }
}
