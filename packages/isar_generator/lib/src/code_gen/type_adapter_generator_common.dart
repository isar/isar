import 'package:dartx/dartx.dart';
import 'package:isar_generator/src/object_info.dart';

String deserializeMethodBody(
  ObjectInfo object,
  String Function(ObjectProperty property) deserializeProperty,
) {
  var code = '''final object = ${object.dartName}(''';
  final propertiesByMode =
      object.properties.groupBy((ObjectProperty p) => p.deserialize);
  final positional = propertiesByMode[PropertyDeser.positionalParam] ?? [];
  final sortedPositional =
      positional.sortedBy((ObjectProperty p) => p.constructorPosition!);
  for (final p in sortedPositional) {
    final deser = deserializeProperty(p);
    code += '$deser,';
  }

  final named = propertiesByMode[PropertyDeser.namedParam] ?? [];
  for (final p in named) {
    final deser = deserializeProperty(p);
    code += '${p.dartName}: $deser,';
  }

  code += ');';

  final assign = propertiesByMode[PropertyDeser.assign] ?? [];
  for (final p in assign) {
    final deser = deserializeProperty(p);
    code += 'object.${p.dartName} = $deser;';
  }

  return code;
}

String generateGetId(ObjectInfo object) {
  return '''
    int? ${object.getIdName}(${object.dartName} object) {
      if (object.${object.idProperty.dartName} == Isar.autoIncrement) {
        return null;
      } else {
        return object.${object.idProperty.dartName};
      }
    }
  ''';
}

String generateGetLinks(ObjectInfo object) {
  return '''
    List<IsarLinkBase<dynamic>> ${object.getLinksName}(${object.dartName} object) {
      return [${object.links.map((e) => 'object.${e.dartName}').join(',')}];
    }
  ''';
}

String generateAttach(ObjectInfo object) {
  var code = '''
  void ${object.attachName}(IsarCollection<dynamic> col, Id id, ${object.dartName} object) {''';

  if (object.idProperty.assignable) {
    code += 'object.${object.idProperty.dartName} = id;';
  }

  for (final link in object.links) {
    // ignore: leading_newlines_in_multiline_strings
    code += '''object.${link.dartName}.attach(
      col,
      col.isar.collection<${link.targetCollectionDartName}>(),
      r'${link.isarName}',
      id
    );''';
  }
  return '$code}';
}

String generateEnumMaps(ObjectInfo object) {
  var code = '';
  for (final property in object.properties) {
    final enumName = property.typeClassName;
    if (property.isEnum) {
      code += 'const ${property.enumValueMapName(object)} = {';
      for (final enumElementName in property.enumMap!.keys) {
        final value = property.enumMap![enumElementName];
        if (value is String) {
          code += "$enumName.$enumElementName: r'$value',";
        } else {
          code += '$enumName.$enumElementName: $value,';
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
  }

  return code;
}
