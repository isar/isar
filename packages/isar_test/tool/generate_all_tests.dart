import 'dart:io';

void main() {
  final testDir = Directory('test');
  final files = testDir
      .listSync(recursive: true)
      .where((e) => e is File && e.path.split('.').length == 2)
      .map((e) => e.path)
      .toList();

  final imports = files.map((e) {
    return "import '../$e' as ${e.split('.')[0].replaceAll('/', '_')};";
  }).join('\n');

  final calls = files.map((e) {
    return "${e.split('.')[0].replaceAll('/', '_')}.main();";
  }).join('\n');

  final code = """
    $imports

    void main() {
      $calls
    }
  """;

  File('test_driver/all_tests.dart').writeAsStringSync(code);
}
