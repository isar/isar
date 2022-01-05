import 'dart:io';

void main() {
  final file = File('lib/src/native/bindings.dart');
  var contents = file.readAsStringSync();
  contents = contents.replaceAll(
    'ffi.Pointer<DartCObject>',
    'ffi.Pointer<ffi.Dart_CObject>',
  );
  contents = contents.replaceAll(
    RegExp(r'ffi\.Pointer<(?!(ffi|IsarCoreBindings|RawObject|T))[^>]+>'),
    'ffi.Pointer<ffi.NativeType>',
  );
  contents = contents.replaceAll(
    RegExp(r'class (?!(IsarCoreBindings|RawObject))[^}]+}'),
    '',
  );
  file.writeAsStringSync(contents);
}
