import 'dart:io';

void main() {
  final testDir = Directory('test');
  final files = testDir
      .listSync(recursive: true)
      .where((e) => e is File && e.path.endsWith('_test.dart'))
      .map((e) => e.path)
      .toList();

  final imports = files.map((e) {
    return "import '$e' as ${e.split('.')[0].replaceAll('/', '_')};";
  }).join('\n');

  final calls = files.map((e) {
    final content = File(e).readAsStringSync();
    final call = "${e.split('.')[0].replaceAll('/', '_')}.main();";
    if (content.startsWith("@TestOn('vm')")) {
      return 'if (!kIsWeb) $call';
    } else {
      return call;
    }
  }).join('\n');

  final code = """
    import 'test/util/common.dart';
    $imports

    void main() {
      $calls
    }
  """;

  File('all_tests.dart').writeAsStringSync(code);
}
