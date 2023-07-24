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
    return "import '../$dartPath' as $name;";
  }).join('\n');

  final calls = files.map((String e) {
    var call = "${e.split('.')[0].replaceAll(p.separator, '_')}.main();";
    if (e.contains('stress')) {
      call = 'if (stress) $call';
    }
    return call;
  }).join('\n');

  final code = """
    // ignore_for_file: directives_ordering

    $imports

    void main() {
      const stress = bool.fromEnvironment('STRESS');
      $calls
    }
""";

  Directory('integration_test').createSync();
  File('integration_test${p.separator}all_tests.dart').writeAsStringSync(code);
}
