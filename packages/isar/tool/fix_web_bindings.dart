import 'dart:io';

const path = 'lib/src/web/bindings.dart';

void main() {
  var content = File(path).readAsStringSync();

  content = content.replaceFirst("import 'dart:ffi' as ffi;", '''
import 'package:isar/src/web/ffi.dart' as ffi;
import 'package:isar/src/web/interop.dart';

extension IsarBindingsX on JSIsar {
''');

  content = content.replaceFirst('final', '''
}

final
''');

  File(path).writeAsStringSync(content);
}
