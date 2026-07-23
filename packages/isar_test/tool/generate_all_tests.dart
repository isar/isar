import 'dart:io';
import 'package:path/path.dart' as p;

void main() {
  final files = Directory('test')
      .listSync(recursive: true)
      .where((FileSystemEntity e) => e is File && e.path.endsWith('_test.dart'))
      .map((FileSystemEntity e) => e.path)
      .where((String path) => !path.contains('web_conformance_'))
      .toList()
    ..sort();

  final imports = files.map((String e) {
    final dartPath = e.replaceAll(p.separator, '/');
    final name = e.split('.')[0].replaceAll(p.separator, '_');
    return "import '../$dartPath' as $name;";
  }).join('\n');
  final webImports = files.map((String e) {
    final dartPath = e.replaceAll(p.separator, '/').substring('test/'.length);
    final name = e.split('.')[0].replaceAll(p.separator, '_');
    return "import '$dartPath' as $name;";
  }).join('\n');

  final calls = files.asMap().entries.map((entry) {
    final index = entry.key;
    final e = entry.value;
    final content = File(e).readAsStringSync();
    var call = "${e.split('.')[0].replaceAll(p.separator, '_')}.main();";
    if (e.contains('stress')) {
      call = 'if (stress) $call';
    }
    if (content.startsWith("@TestOn('vm')")) {
      call = 'if (!kIsWeb) $call';
    }
    return 'if ($index % shardCount == shardIndex) $call';
  }).join('\n');

  final code = """
    // ignore_for_file: directives_ordering

    import 'package:isar_test/isar_test.dart';
    $imports

    void main({int shardIndex = 0, int shardCount = 1}) {
      const stress = bool.fromEnvironment('STRESS');
      $calls
    }
""";

  Directory('integration_test').createSync();
  File('integration_test${p.separator}all_tests.dart').writeAsStringSync(code);
  File('test${p.separator}all_tests.dart').writeAsStringSync(
    code.replaceFirst(imports, webImports),
  );
}
