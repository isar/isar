part of isar_generator;

String _generatePropertyMapper(ObjectInfo object) {
  var index = 1;
  return '''
    const ${object.dartName.capitalize()}PropertyMapper = <String, int>{
      ${object.properties.map((e) => '"${e.dartName}":${index++}').join(",")}
    };''';
}
