import 'package:dartx/dartx.dart';
import '../helper.dart';
import '../object_info.dart';

String generateByIndexExtension(ObjectInfo oi) {
  final List<ObjectIndex> uniqueIndexes =
      oi.indexes.where((ObjectIndex e) => e.unique).toList();
  if (uniqueIndexes.isEmpty) {
    return '';
  }
  String code =
      'extension ${oi.dartName}ByIndex on IsarCollection<${oi.dartName}> {';
  for (final ObjectIndex index in uniqueIndexes) {
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
    return properties
        .map((ObjectIndexProperty e) => e.property.dartName.capitalize())
        .join();
  }
}

String generateSingleByIndex(ObjectInfo oi, ObjectIndex index) {
  final String params = index.properties
      .map((ObjectIndexProperty i) =>
          '${i.property.dartType} ${i.property.dartName}')
      .join(',');
  final String paramsList = index.properties
      .map((ObjectIndexProperty i) => i.property.dartName)
      .join(',');
  return '''
    Future<${oi.dartName}?> getBy${index.dartName}($params) {
      return getByIndex('${index.name.esc}', [$paramsList]);
    }

    ${oi.dartName}? getBy${index.dartName}Sync($params) {
      return getByIndexSync('${index.name.esc}', [$paramsList]);
    }

    Future<bool> deleteBy${index.dartName}($params) {
      return deleteByIndex('${index.name.esc}', [$paramsList]);
    }

    bool deleteBy${index.dartName}Sync($params) {
      return deleteByIndexSync('${index.name.esc}', [$paramsList]);
    }
  ''';
}

String generateAllByIndex(ObjectInfo oi, ObjectIndex index) {
  String valsName(ObjectProperty p) => '${p.dartName}Values';

  final List<ObjectIndexProperty> props = index.properties;
  final String params = props
      .map((ObjectIndexProperty ip) =>
          'List<${ip.property.dartType}> ${valsName(ip.property)}')
      .join(',');
  String createValues;
  if (props.length == 1) {
    final ObjectProperty p = props.first.property;
    createValues = 'final values = ${valsName(p)}.map((e) => [e]).toList();';
  } else {
    final String lenAssert = props
        .sublist(1)
        .map((ObjectIndexProperty i) => '${valsName(i.property)}.length == len')
        .join('&&');
    createValues = '''
      final len = ${valsName(props.first.property)}.length;
      assert($lenAssert, 'All index values must have the same length');
      final values = <List<dynamic>>[];
      for (var i = 0; i < len; i++) {
        values.add([${props.map((ObjectIndexProperty ip) => '${valsName(ip.property)}[i]').join(',')}]);
      }
    ''';
  }
  return '''
    Future<List<${oi.dartName}?>> getAllBy${index.dartName}($params) {
      $createValues
      return getAllByIndex('${index.name.esc}', values);
    }

    List<${oi.dartName}?> getAllBy${index.dartName}Sync($params) {
      $createValues
      return getAllByIndexSync('${index.name.esc}', values);
    }

    Future<int> deleteAllBy${index.dartName}($params) {
      $createValues
      return deleteAllByIndex('${index.name.esc}', values);
    }

    int deleteAllBy${index.dartName}Sync($params) {
      $createValues
      return deleteAllByIndexSync('${index.name.esc}', values);
    }
  ''';
}

String generatePutByIndex(ObjectInfo oi, ObjectIndex index) {
  return '''
    Future<int> putBy${index.dartName}(${oi.dartName} object) {
      return putByIndex('${index.name.esc}', object);
    }

    int putBy${index.dartName}Sync(${oi.dartName} object, {bool saveLinks = false}) {
      return putByIndexSync('${index.name.esc}', object, saveLinks: saveLinks);
    }

    Future<List<int>> putAllBy${index.dartName}(List<${oi.dartName}> objects) {
      return putAllByIndex('${index.name.esc}', objects);
    }

    List<int> putAllBy${index.dartName}Sync(List<${oi.dartName}> objects, {bool saveLinks = false}) {
      return putAllByIndexSync('${index.name.esc}', objects, saveLinks: saveLinks);
    }
  ''';
}
