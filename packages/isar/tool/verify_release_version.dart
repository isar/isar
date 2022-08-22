import 'package:isar/isar.dart';

void main() {
  const releaseName = String.fromEnvironment('GITHUB_REF_NAME');
  if (releaseName != Isar.version) {
    throw StateError(
      'Invalid Isar version for release: $releaseName != ${Isar.version}',
    );
  }
}
