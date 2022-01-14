import 'package:dartx/dartx.dart';
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
  final getDeleteAllParams =
      "'${index.properties.first.property.dartName}', [[$paramsList]]";
  return '''
    Future<${oi.dartName}?> getBy${index.dartName}($params) {
      // ignore: invalid_use_of_protected_member
      return getAllByIndex($getDeleteAllParams).then((e) => e[0]);
    }

    ${oi.dartName}? getBy${index.dartName}Sync($params) {
      // ignore: invalid_use_of_protected_member
      return getAllByIndexSync($getDeleteAllParams)[0];
    }

    Future<bool> deleteBy${index.dartName}($params) {
      // ignore: invalid_use_of_protected_member
      return deleteAllByIndex($getDeleteAllParams).then((e) => e == 1);
    }

    bool deleteBy${index.dartName}Sync($params) {
      // ignore: invalid_use_of_protected_member
      return getAllByIndexSync($getDeleteAllParams) == 1;
    }
  ''';
}

String generateAllByIndex(ObjectInfo oi, ObjectIndex index) {
  return '''
    Future<List<${oi.dartName}?>> getAllBy${index.dartName}(List<List<Object?>> values) {
      // ignore: invalid_use_of_protected_member
      return getAllByIndex('${index.name}', values);
    }

    List<${oi.dartName}?> getAllBy${index.dartName}Sync(List<List<Object?>> values) {
      // ignore: invalid_use_of_protected_member
      return getAllByIndexSync('${index.name}', values);
    }

    Future<int> deleteAllBy${index.dartName}(List<List<Object?>> values) {
      // ignore: invalid_use_of_protected_member
      return deleteAllByIndex('${index.name}', values);
    }

    int deleteAllBy${index.dartName}Sync(List<List<Object?>> values) {
      // ignore: invalid_use_of_protected_member
      return deleteAllByIndexSync('${index.name}', values);
    }
  ''';
}
