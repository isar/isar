import 'dart:io';
import 'package:path/path.dart' as p;

void main() {
  final Directory testDir = Directory('test');
  final List<String> files = testDir
      .listSync(recursive: true)
      .where((FileSystemEntity e) => e is File && e.path.endsWith('_test.dart'))
      .map((FileSystemEntity e) => e.path)
      .toList();

  final String imports = files.map((String e) {
    return "import '$e' as ${e.split('.')[0].replaceAll(p.separator, '_')};";
  }).join('\n');

  final String calls = files.map((String e) {
    final String content = File(e).readAsStringSync();
    final String call = "${e.split('.')[0].replaceAll(p.separator, '_')}.main();";
    if (content.startsWith("@TestOn('vm')")) {
      return 'if (!kIsWeb) $call';
    } else {
      return call;
    }
  }).join('\n');

  final String code = """
    import 'test/util/common.dart';
    $imports

    void main() {
      $calls
    }
  """;

  File('all_tests.dart').writeAsStringSync(code);
}
