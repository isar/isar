import 'dart:io';

void main() {
  final file = File('lib/src/native/bindings.dart');
  var contents = file.readAsStringSync();
  contents = contents.replaceAll(
    'ffi.Pointer<Dart_CObject>',
    'ffi.Pointer<ffi.Dart_CObject>',
  );
  contents = contents.replaceAll(
    RegExp(r'ffi\.Pointer<(?!(ffi|IsarCoreBindings|RawObject))[^>]+>'),
    'ffi.Pointer<ffi.NativeType>',
  );
  contents = contents.replaceAll(
    RegExp(r'class (?!(IsarCoreBindings|RawObject))[^}]+}'),
    '',
  );
  contents = '// @dart=2.8\n$contents';
  file.writeAsStringSync(contents);
}
