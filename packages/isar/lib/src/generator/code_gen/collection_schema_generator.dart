part of isar_generator;

String _generateSchema(ObjectInfo object) {
  String generatePropertySchema(PropertyInfo p) {
    return '''
    IsarPropertySchema(
      name: '${p.isarName}',
      type: IsarType.${p.type.name},
      ${p.targetIsarName != null ? "target: '${p.targetIsarName}'," : ''}
      ${p.enumMap != null ? 'enumMap: ${jsonEncode(p.enumMap)},' : ''}
    ),''';
  }

  String generateIndexSchema(IndexInfo index) {
    return '''
    IsarIndexSchema(
      name: '${index.name}',
      properties: [${index.properties.map((e) => '"$e",').join()}],
      unique: ${index.unique},
      hash: ${index.hash},
    ),''';
  }

  final embeddedSchemas =
      object.embeddedDartNames.map((e) => '${e.capitalize()}Schema').join(',');
  final properties = object.properties
      .where((e) => !e.isId || e.type != IsarType.long)
      .map(generatePropertySchema)
      .join();
  final indexes = object.indexes.map(generateIndexSchema).join();
  return '''
    const ${object.dartName.capitalize()}Schema = IsarGeneratedSchema(
      schema: IsarSchema(
        name: '${object.isarName}',
        ${object.idProperty != null ? "idName: '${object.idProperty!.isarName}'," : ''}
        embedded: ${object.isEmbedded},
        properties: [$properties],
        indexes: [$indexes],
      ),
      converter: IsarObjectConverter<${object.idProperty?.dartType ?? 'void'}, ${object.dartName}>(
        serialize: serialize${object.dartName},
        deserialize: deserialize${object.dartName},
        ${!object.isEmbedded ? 'deserializeProperty: deserialize${object.dartName}Prop,' : ''}
      ),
      ${object.isEmbedded ? '' : 'embeddedSchemas: [$embeddedSchemas],'}
    );''';
}
