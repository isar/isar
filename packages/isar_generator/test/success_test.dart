import 'dart:io';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:isar_generator/isar_generator.dart';
import 'package:test/test.dart';

void main() {
  group('Success case', () {
    for (final file in Directory('test/successes').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;

      test(file.path, () async {
        final content = await file.readAsString();
        await testBuilder(
          getIsarGenerator(BuilderOptions.empty),
          {'a|${file.path}': content},
          reader: await PackageAssetReader.currentIsolate(),
        );
      });
    }
  });
}
