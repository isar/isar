import 'package:isar_generator/src/object_info.dart';

String generateIsarInterface(List<ObjectInfo> objects) {
  return '''
    class _GeneratedIsarInterface implements IsarInterface {
      @override
      String get schemaJson => _schema;

      @override
      List<String> get instanceNames => _isar.keys.toList();

      @override
      ${_generateGetCollection(objects)}

      @override
      ${_generateObjectToJson(objects)}
    }
    ''';
}

String _generateGetCollection(List<ObjectInfo> objects) {
  var code = '''
  IsarCollection getCollection(String instanceName, String collectionName) {
    final instance = _isar[instanceName];
    if (instance == null) throw 'Isar instance \$instanceName is not open';
    switch (collectionName) {
  ''';
  for (var object in objects) {
    code += '''
    case '${object.isarName}':
      return ${object.collectionVar}[instanceName]!;''';
  }
  code += '''
      default:
        throw 'Unknown collection';
    }
  }''';
  return code;
}

String _generateObjectToJson(List<ObjectInfo> objects) {
  var code = 'Map<String, dynamic> objectToJson(dynamic object) {';
  for (var object in objects) {
    code += '''
    if (object is ${object.dartName}) {
      return {''';
    for (var p in object.properties) {
      code += "'${p.isarName}': object.${p.dartName},";
    }
    code += '''
      };
    }''';
  }
  code += '''
    throw 'Unknown object type';
  }''';
  return code;
}
