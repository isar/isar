// ignore_for_file: use_string_buffers

import 'package:isar/src/generator/object_info.dart';

String generateEnumMaps(ObjectInfo object) {
  var code = '';
  for (final property in object.properties.where((e) => e.isEnum)) {
    final enumName = property.typeClassName;
    code += 'const ${property.enumValueMapName(object)} = {';
    for (final enumElementName in property.enumMap!.keys) {
      final value = property.enumMap![enumElementName];
      if (value is String) {
        code += "r'$enumElementName': r'$value',";
      } else {
        code += "'$enumElementName': $value,";
      }
    }
    code += '};';

    code += 'const ${property.valueEnumMapName(object)} = {';
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