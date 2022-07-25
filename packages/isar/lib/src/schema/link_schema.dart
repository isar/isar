part of isar;

class LinkSchema {
  /// @nodoc
  @protected
  LinkSchema({
    required this.id,
    required this.name,
    required this.target,
    required this.isSingle,
    this.linkName,
  });

  final int id;
  final String name;

  final String target;
  final bool isSingle;
  final String? linkName;

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
