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

String generateAttachLinks(ObjectInfo object) {
  var code = '''
  void ${object.attachLinksName}(IsarCollection<dynamic> col, int id, ${object.dartName} object) {''';

  for (final link in object.links) {
    // ignore: leading_newlines_in_multiline_strings
    code += '''object.${link.dartName}.attach(
      col,
      col.isar.${link.targetCollectionAccessor},
      r'${link.isarName}',
      id
    );''';
  }
  return '$code}';
}
