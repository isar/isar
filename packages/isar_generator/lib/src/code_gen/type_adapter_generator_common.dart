import 'package:dartx/dartx.dart';
import '../helper.dart';
import '../object_info.dart';

String deserializeMethodBody(ObjectInfo object,
    String Function(ObjectProperty property) deserializeProperty) {
  String code = '''final object = ${object.dartName}(''';
  final Map<PropertyDeser, List<ObjectProperty>> propertiesByMode =
      object.properties.groupBy((ObjectProperty p) => p.deserialize);
  final List<ObjectProperty> positional =
      propertiesByMode[PropertyDeser.positionalParam] ?? [];
  final SortedList<ObjectProperty> sortedPositional =
      positional.sortedBy((ObjectProperty p) => p.constructorPosition!);
  for (final ObjectProperty p in sortedPositional) {
    final String deser = deserializeProperty(p);
    code += '$deser,';
  }

  final List<ObjectProperty> named =
      propertiesByMode[PropertyDeser.namedParam] ?? [];
  for (final ObjectProperty p in named) {
    final String deser = deserializeProperty(p);
    code += '${p.dartName}: $deser,';
  }

  code += ');';

  final List<ObjectProperty> assign =
      propertiesByMode[PropertyDeser.assign] ?? [];
  for (final ObjectProperty p in assign) {
    final String deser = deserializeProperty(p);
    code += 'object.${p.dartName} = $deser;';
  }

  return code;
}

String generateAttachLinks(ObjectInfo object) {
  String code = '''
  void ${object.attachLinksName}(IsarCollection<dynamic> col, int id, ${object.dartName} object) {''';

  for (final ObjectLink link in object.links) {
    // ignore: leading_newlines_in_multiline_strings
    code += '''object.${link.dartName}.attach(
      col,
      col.isar.${link.targetCollectionAccessor},
      '${link.isarName.esc}',
      id
    );''';
  }
  return '$code}';
}
