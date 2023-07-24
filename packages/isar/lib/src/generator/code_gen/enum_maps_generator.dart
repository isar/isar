// ignore_for_file: use_string_buffers

part of isar_generator;

String _generateEnumMaps(ObjectInfo object) {
  var code = '';
  for (final property in object.properties.where((e) => e.isEnum)) {
    final enumName = property.typeClassName;
    code += 'const ${property.enumMapName(object)} = {';
    for (final enumElementName in property.enumMap!.keys) {
      final value = property.enumMap![enumElementName];
      if (value is String) {
        code += "r'$value': $enumName.$enumElementName,";
      } else {
        code += '$value: $enumName.$enumElementName,';
      }
    }
    code += '};';
  }

  return code;
}
