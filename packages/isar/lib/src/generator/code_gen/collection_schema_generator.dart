part of isar_generator;

String _generateSchema(ObjectInfo object) {
  final json = {
    'name': object.isarName,
    'idName': object.idProperty?.isarName,
    if (object.isEmbedded) 'embedded': object.isEmbedded,
    'properties': [
      for (final prop in object.properties)
        if (!prop.isId || prop.type != PropertyType.long)
          {
            'name': prop.isarName,
            'type': prop.type.name.capitalize(),
            if (prop.type.isObject) 'target': prop.targetIsarName,
            if (prop.isEnum) 'enumMap': prop.enumMap,
          }
    ],
    if (object.indexes.isNotEmpty)
      'indexes': [
        for (final index in object.indexes)
          {
            'name': index.name,
            'unique': index.unique,
            'properties': index.properties,
            'hash': index.hash,
          }
      ],
  };
  final schemaJson = jsonEncode(json);

  if (object.isEmbedded) {
    return '''
    //const ${object.dartName.decapitalize()}SchemaHash = ${Isar.fastHash(schemaJson)};
    const ${object.dartName.capitalize()}Schema = IsarSchema(
      schema: '$schemaJson',
      converter: IsarObjectConverter<void, ${object.dartName}>(
        serialize: serialize${object.dartName},
        deserialize: deserialize${object.dartName},
      ),
    );''';
  } else {
    final embeddedSchemas = object.embeddedDartNames
        .map((e) => '${e.capitalize()}Schema')
        .join(',');
    var hash = Isar.fastHash(schemaJson).toString();
    for (final embedded in object.embeddedDartNames) {
      hash = '($hash * 31 + ${embedded.decapitalize()}SchemaHash)';
    }

    return '''
    const ${object.dartName.capitalize()}Schema = IsarCollectionSchema(
      schema: '$schemaJson',
      converter: IsarObjectConverter<${object.idProperty!.dartType}, ${object.dartName}>(
        serialize: serialize${object.dartName},
        deserialize: deserialize${object.dartName},
        deserializeProperty: deserialize${object.dartName}Prop,
      ),
      embeddedSchemas: [$embeddedSchemas],
      //hash: $hash,
    );''';
  }
}
