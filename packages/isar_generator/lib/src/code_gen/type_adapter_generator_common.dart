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
