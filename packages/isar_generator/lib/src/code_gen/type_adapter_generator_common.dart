import 'package:dartx/dartx.dart';
import 'package:isar_generator/src/helper.dart';
import 'package:isar_generator/src/object_info.dart';

String deserializeMethodBody(ObjectInfo object,
    String Function(ObjectProperty property) deserializeProperty) {
  var code = '''final object = ${object.dartName}(''';
  final propertiesByMode = object.properties.groupBy((p) => p.deserialize);
  final positional = propertiesByMode[PropertyDeser.positionalParam] ?? [];
  final sortedPositional = positional.sortedBy((p) => p.constructorPosition!);
  for (var p in sortedPositional) {
    final deser = deserializeProperty(p);
    code += '$deser,';
  }

  final named = propertiesByMode[PropertyDeser.namedParam] ?? [];
  for (var p in named) {
    final deser = deserializeProperty(p);
    code += '${p.dartName}: $deser,';
  }

  code += ');';

  final assign = propertiesByMode[PropertyDeser.assign] ?? [];
  for (var p in assign) {
    final deser = deserializeProperty(p);
    code += 'object.${p.dartName} = $deser;';
  }

  if (object.links.isNotEmpty) {
    code += 'attachLinks(collection.isar, object);';
  }

  return '''
    $code
    return object;''';
}

String generateAttachLinks(ObjectInfo object) {
  if (object.links.isEmpty) {
    return '';
  }

  var code = 'void attachLinks(Isar isar, ${object.dartName} object) {';

  for (var link in object.links) {
    code += '''object.${link.dartName}.attach(
      isar.${object.accessor},
      isar.getCollection<${link.targetCollectionDartName}>('${link.targetCollectionIsarName.esc}'),
      object,
      '${link.isarName.esc}',
      ${link.backlink},
    );
    ''';
  }
  return code + '}';
}
