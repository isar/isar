import 'dart:io';

void main() {
  final file = File('lib/src/native/bindings.dart');
  var contents = file.readAsStringSync();
  contents = contents.replaceAll(
    RegExp(
        r'ffi\.Pointer<(?!(ffi|IsarCoreBindings|RawObject|Dart_CObject))[^>]+>'),
    'ffi.Pointer<ffi.NativeType>',
  );
  contents = contents.replaceAll(
    RegExp(r'class (?!(IsarCoreBindings|RawObject|Dart_CObject))[^}]+}'),
    '',
  );
  file.writeAsStringSync(contents);
}
