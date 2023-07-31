import 'dart:io';
import 'package:path/path.dart' as p;

void main() {
  final files = Directory('test')
      .listSync(recursive: true)
      .where((FileSystemEntity e) => e is File && e.path.endsWith('_test.dart'))
      .map((FileSystemEntity e) => e.path)
      .toList();

  final imports = files.map((String e) {
    final dartPath = e.replaceAll(p.separator, '/');
    final name = e.split('.')[0].replaceAll(p.separator, '_');
    return "import '$dartPath' as $name;";
  }).join('\n');

  final calls = files.map((String e) {
    final content = File(e).readAsStringSync();
    var call = "${e.split('.')[0].replaceAll(p.separator, '_')}.main();";
    if (e.contains('stress')) {
      call = 'if (stress) $call';
    }
    if (content.startsWith("@TestOn('vm')")) {
      return 'if (!kIsWeb) $call';
    } else {
      return call;
    }
  }).join('\n');

  final code = """
    // ignore_for_file: directives_ordering

    import 'package:isar_test/isar_test.dart';
    $imports

    void main() {
      const stress = bool.fromEnvironment('STRESS');
      $calls
    }
""";

  File('all_tests.dart').writeAsStringSync(code);
}
