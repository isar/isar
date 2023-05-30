part of isar;

/// Isar databases can contain unused space that will be reused for later
/// operations. You can specify conditions to trigger manual compaction where
/// the entire database is copied and unused space freed.
///
/// This operation can only be performed while a database is being opened and
/// should only be used if absolutely necessary.
class CompactCondition {
  /// Compaction will happen if all of the specified conditions are true.
  const CompactCondition({
    this.minFileSize,
    this.minBytes,
    this.minRatio,
  }) : assert(
          minFileSize != null || minBytes != null || minRatio != null,
          'At least one condition needs to be specified.',
        );

  /// The minimum size in bytes of the database file to trigger compaction. It
  /// is highly  discouraged to trigger compaction solely on this condition.
  final int? minFileSize;

  /// The minimum number of bytes that can be freed with compaction.
  final int? minBytes;

  /// The minimum compaction ration. For example `2.0` would trigger compaction
  /// as soon as the file size can be halved.
  final double? minRatio;
}
