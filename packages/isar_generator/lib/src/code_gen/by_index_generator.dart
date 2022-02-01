import 'package:dartx/dartx.dart';
import 'package:isar_generator/src/helper.dart';
import 'package:isar_generator/src/object_info.dart';

String generateByIndexExtension(ObjectInfo oi) {
  final uniqueIndexes = oi.indexes.where((e) => e.unique).toList();
  if (uniqueIndexes.isEmpty) {
    return '';
  }
  var code =
      'extension ${oi.dartName}ByIndex on IsarCollection<${oi.dartName}> {';
  for (var index in uniqueIndexes) {
    code += generateSingleByIndex(oi, index);
    code += generateAllByIndex(oi, index);
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
