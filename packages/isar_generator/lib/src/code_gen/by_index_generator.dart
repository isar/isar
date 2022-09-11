import 'package:dartx/dartx.dart';
import 'package:isar_generator/src/object_info.dart';

String generateByIndexExtension(ObjectInfo oi) {
  final uniqueIndexes = oi.indexes.where((e) => e.unique).toList();
  if (uniqueIndexes.isEmpty) {
    return '';
  }
  var code =
      'extension ${oi.dartName}ByIndex on IsarCollection<${oi.dartName}> {';
  for (final index in uniqueIndexes) {
    code += generateSingleByIndex(oi, index);
    code += generateAllByIndex(oi, index);
    if (!index.properties.first.isMultiEntry) {
      code += generatePutByIndex(oi, index);
    }
  }
  return '''
    $code
  }''';
}

extension on ObjectIndex {
  String get dartName {
    return properties.map((e) => e.property.dartName.capitalize()).join();
  }
}

String generateSingleByIndex(ObjectInfo oi, ObjectIndex index) {
  final params = index.properties
      .map((i) => '${i.property.dartType} ${i.property.dartName}')
      .join(',');
  final paramsList = index.properties.map((i) => i.property.dartName).join(',');
  return '''
    Future<${oi.dartName}?> getBy${index.dartName}($params) {
      return getByIndex(r'${index.name}', [$paramsList]);
    }

    ${oi.dartName}? getBy${index.dartName}Sync($params) {
      return getByIndexSync(r'${index.name}', [$paramsList]);
    }

    Future<bool> deleteBy${index.dartName}($params) {
      return deleteByIndex(r'${index.name}', [$paramsList]);
    }

    bool deleteBy${index.dartName}Sync($params) {
      return deleteByIndexSync(r'${index.name}', [$paramsList]);
    }
  ''';
}

String generateAllByIndex(ObjectInfo oi, ObjectIndex index) {
  String valsName(ObjectProperty p) => '${p.dartName}Values';

  final props = index.properties;
  final params = props
      .map((ip) => 'List<${ip.property.dartType}> ${valsName(ip.property)}')
      .join(',');
  String createValues;
  if (props.length == 1) {
    final p = props.first.property;
    createValues = 'final values = ${valsName(p)}.map((e) => [e]).toList();';
  } else {
    final lenAssert = props
        .sublist(1)
        .map((i) => '${valsName(i.property)}.length == len')
        .join('&&');
    createValues = '''
      final len = ${valsName(props.first.property)}.length;
      assert($lenAssert, 'All index values must have the same length');
      final values = <List<dynamic>>[];
      for (var i = 0; i < len; i++) {
        values.add([${props.map((ip) => '${valsName(ip.property)}[i]').join(',')}]);
      }
    ''';
  }
  return '''
    Future<List<${oi.dartName}?>> getAllBy${index.dartName}($params) {
      $createValues
      return getAllByIndex(r'${index.name}', values);
    }

    List<${oi.dartName}?> getAllBy${index.dartName}Sync($params) {
      $createValues
      return getAllByIndexSync(r'${index.name}', values);
    }

    Future<int> deleteAllBy${index.dartName}($params) {
      $createValues
      return deleteAllByIndex(r'${index.name}', values);
    }

    int deleteAllBy${index.dartName}Sync($params) {
      $createValues
      return deleteAllByIndexSync(r'${index.name}', values);
    }
  ''';
}

String generatePutByIndex(ObjectInfo oi, ObjectIndex index) {
  return '''
    Future<Id> putBy${index.dartName}(${oi.dartName} object) {
      return putByIndex(r'${index.name}', object);
    }

    Id putBy${index.dartName}Sync(${oi.dartName} object, {bool saveLinks = true}) {
      return putByIndexSync(r'${index.name}', object, saveLinks: saveLinks);
    }

    Future<List<Id>> putAllBy${index.dartName}(List<${oi.dartName}> objects) {
      return putAllByIndex(r'${index.name}', objects);
    }

    List<Id> putAllBy${index.dartName}Sync(List<${oi.dartName}> objects, {bool saveLinks = true}) {
      return putAllByIndexSync(r'${index.name}', objects, saveLinks: saveLinks);
    }
  ''';
}
