import 'package:isar/src/generator/isar_type.dart';
import 'package:isar/src/generator/object_info.dart';

const _updateableTypes = [
  PropertyType.bool,
  PropertyType.byte,
  PropertyType.int,
  PropertyType.long,
  PropertyType.float,
  PropertyType.double,
  PropertyType.dateTime,
  PropertyType.string,
];

String generateUpdate(ObjectInfo oi) {
  final updateProperties = oi.properties
      .where((p) => !p.isId && _updateableTypes.contains(p.type))
      .toList();

  if (updateProperties.isEmpty) {
    return '';
  }

  return '''
  sealed class _${oi.dartName}Update {
    bool call(
      ${oi.idProperty!.dartType} ${oi.idProperty!.dartName}, {
      ${updateProperties.map((p) => '${p.scalarDartTypeNotNull}? ${p.dartName},').join('\n')}
    });
  }

  class _${oi.dartName}UpdateImpl implements _${oi.dartName}Update {
    const _${oi.dartName}UpdateImpl(this.collection);

    final IsarCollection<${oi.idProperty!.dartType}, ${oi.dartName}> collection;

    @override
    bool call(
      ${oi.idProperty!.dartType} ${oi.idProperty!.dartName}, {
      ${updateProperties.map((p) => 'Object? ${p.dartName} = ignore,').join('\n')}
    }) {
      return collection.updateProperties(
        [${oi.idProperty!.dartName}], 
        {
          ${updateProperties.map((p) => 'if (${p.dartName} != ignore) ${p.index}: ${p.dartName} as ${p.scalarDartTypeNotNull}?,').join('\n')}
        }
      ) > 0;
    }
  }

  sealed class _${oi.dartName}UpdateAll {
    int call(
      List<${oi.idProperty!.dartType}> ${oi.idProperty!.dartName}, {
      ${updateProperties.map((p) => '${p.scalarDartTypeNotNull}? ${p.dartName},').join('\n')}
    });
  }

  class _${oi.dartName}UpdateAllImpl implements _${oi.dartName}UpdateAll {
    const _${oi.dartName}UpdateAllImpl(this.collection);

    final IsarCollection<${oi.idProperty!.dartType}, ${oi.dartName}> collection;

    @override
    int call(
      List<${oi.idProperty!.dartType}> ${oi.idProperty!.dartName}, {
      ${updateProperties.map((p) => 'Object? ${p.dartName} = ignore,').join('\n')}
    }) {
      return collection.updateProperties(
        ${oi.idProperty!.dartName}, 
        {
          ${updateProperties.map((p) => 'if (${p.dartName} != ignore) ${p.index}: ${p.dartName} as ${p.scalarDartTypeNotNull}?,').join('\n')}
        }
      );
    }
  }

  extension ${oi.dartName}Update on IsarCollection<${oi.idProperty!.dartType}, ${oi.dartName}> {
    _${oi.dartName}Update get update => _${oi.dartName}UpdateImpl(this);

    _${oi.dartName}UpdateAll get updateAll => _${oi.dartName}UpdateAllImpl(this);
  }
  ''';
}
