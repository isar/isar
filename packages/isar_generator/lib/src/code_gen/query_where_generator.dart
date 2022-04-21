import 'package:isar/isar.dart';
import 'package:isar_generator/src/helper.dart';
import 'package:isar_generator/src/isar_type.dart';
import 'package:isar_generator/src/object_info.dart';
import 'package:dartx/dartx.dart';

class WhereGenerator {
  final ObjectInfo object;
  final String objName;
  final ObjectProperty id;
  final existing = <String>{};

  WhereGenerator(this.object)
      : objName = object.dartName,
        id = object.idProperty;

  String generate() {
    var code =
        'extension ${objName}QueryWhereSort on QueryBuilder<$objName, $objName, QWhere> {';

    code += generateAnyId();
    for (var index in object.indexes) {
      code += generateAny(index.name, index.properties);
    }

    code += '''
  }

  extension ${objName}QueryWhere on QueryBuilder<$objName, $objName, QWhereClause> {
  ''';

    code += generateWhereIdEqualTo();
    code += generateWhereIdNotEqualTo();
    code += generateWhereIdGreaterThan();
    code += generateWhereIdLessThan();
    code += generateWhereIdBetween();

    for (var index in object.indexes) {
      for (var n = 0; n < index.properties.length; n++) {
        var properties = index.properties.sublist(0, n + 1);

        final lastProperty = properties.last;
        if (!properties.containsFloat) {
          code += generateWhereEqualTo(index.name, properties);
          code += generateWhereNotEqualTo(index.name, properties);
        }

        if (index.properties.length == 1 && lastProperty.property.nullable) {
          code += generateWhereIsNull(index.name, lastProperty);
          code += generateWhereIsNotNull(index.name, lastProperty);
        }

        if (lastProperty.type != IndexType.hash) {
          if (lastProperty.scalarType != IsarType.bool) {
            code += generateWhereGreaterThan(index.name, properties);
            code += generateWhereLessThan(index.name, properties);
            code += generateWhereBetween(index.name, properties);
          }

          if (lastProperty.scalarType == IsarType.string) {
            code += generateWhereStartsWith(index.name, properties);
          }
        }
      }
    }

    return '$code}';
  }

  String joinToName(List<ObjectIndexProperty> properties, bool firstEqualTo) {
    String propertyName(ObjectIndexProperty p, int i) {
      if (i == 0) {
        return p.property.dartName.decapitalize();
      } else {
        return p.property.dartName.capitalize();
      }
    }

    var firstPropertiesName = properties
        .sublist(0, properties.length - 1)
        .mapIndexed((i, p) => propertyName(p, i))
        .join('');

    if (firstPropertiesName.isNotEmpty && firstEqualTo) {
      firstPropertiesName += 'EqualTo';
    }

    firstPropertiesName += propertyName(properties.last, properties.lastIndex);
    if (properties.last.isarType.isList &&
        properties.last.type != IndexType.hash) {
      firstPropertiesName += 'Any';
    }

    return firstPropertiesName;
  }

  String paramType(ObjectIndexProperty p) {
    if (p.property.isarType.isList && p.type != IndexType.hash) {
      return p.isarType.scalarType.dartType(p.property.nullable, false);
    } else {
      return p.property.dartType;
    }
  }

  String paramName(ObjectIndexProperty p) {
    if (p.property.isarType.isList && p.type != IndexType.hash) {
      return '${p.property.dartName}Element';
    } else {
      return p.property.dartName;
    }
  }

  String joinToParams(List<ObjectIndexProperty> properties) {
    return properties
        .map((it) => '${paramType(it)} ${paramName(it)}')
        .join(',');
  }

  String joinToValues(List<ObjectIndexProperty> properties) {
    return properties.map((it) {
      if (it.property.isarType.isList && it.type != IndexType.hash) {
        return '${it.property.dartName}Element';
      } else {
        return it.property.toIsar(it.property.dartName, object);
      }
    }).join(', ');
  }

  String generateAnyId() {
    return '''
    QueryBuilder<$objName, $objName, QAfterWhere> any${id.dartName.capitalize()}() {
      return addWhereClauseInternal(const IdWhereClause.any());
    }
    ''';
  }

  String generateAny(String indexName, List<ObjectIndexProperty> properties) {
    final name = 'any' + joinToName(properties, false).capitalize();
    if (!existing.add(name)) return '';
    return '''
    QueryBuilder<$objName, $objName, QAfterWhere> $name() {
      return addWhereClauseInternal(
        const IndexWhereClause.any(indexName: '${indexName.esc}')
      );
    }
    ''';
  }

  String get mPrefix => 'QueryBuilder<$objName, $objName, QAfterWhereClause>';

  String generateWhereIdEqualTo() {
    final idName = id.dartName.decapitalize();
    return '''
    $mPrefix ${idName}EqualTo(int $idName) {
      return addWhereClauseInternal( IdWhereClause.between(
        lower: $idName,
        includeLower: true,
        upper: $idName,
        includeUpper: true,
      ));
    }
    ''';
  }

  String generateWhereEqualTo(
      String indexName, List<ObjectIndexProperty> properties) {
    final name = joinToName(properties, false) + 'EqualTo';
    if (!existing.add(name)) return '';

    final values = joinToValues(properties);
    final params = joinToParams(properties);
    return '''
    $mPrefix $name($params) {
      return addWhereClauseInternal(IndexWhereClause.equalTo(
        indexName: '${indexName.esc}',
        value: [$values],
      ));
    }
    ''';
  }

  String generateWhereIdNotEqualTo() {
    final idName = id.dartName.decapitalize();
    return '''
    $mPrefix ${idName}NotEqualTo(int $idName) {
      if (whereSortInternal == Sort.asc) {
        return addWhereClauseInternal(
          IdWhereClause.lessThan(upper: $idName, includeUpper: false),
        ).addWhereClauseInternal(
          IdWhereClause.greaterThan(lower: $idName, includeLower: false),
        );
      } else {
        return addWhereClauseInternal(
          IdWhereClause.greaterThan(lower: $idName, includeLower: false),
        ).addWhereClauseInternal(
          IdWhereClause.lessThan(upper: $idName, includeUpper: false),
        );
      }
    }
    ''';
  }

  String generateWhereNotEqualTo(
      String indexName, List<ObjectIndexProperty> properties) {
    final name = joinToName(properties, false) + 'NotEqualTo';
    if (!existing.add(name)) return '';

    final values = joinToValues(properties);
    final params = joinToParams(properties);
    return '''
    $mPrefix $name($params) {
      if (whereSortInternal == Sort.asc) {
        return addWhereClauseInternal(IndexWhereClause.lessThan(
          indexName: '${indexName.esc}',
          upper: [$values],
          includeUpper: false,
        )).addWhereClauseInternal(IndexWhereClause.greaterThan(
          indexName: '${indexName.esc}',
          lower: [$values],
          includeLower: false,
        ));
      } else {
        return addWhereClauseInternal(IndexWhereClause.greaterThan(
          indexName: '${indexName.esc}',
          lower: [$values],
          includeLower: false,
        )).addWhereClauseInternal(IndexWhereClause.lessThan(
          indexName: '${indexName.esc}',
          upper: [$values],
          includeUpper: false,
        ));
      }
    }
    ''';
  }

  String generateWhereIdGreaterThan() {
    final idName = id.dartName.decapitalize();
    return '''
    $mPrefix ${idName}GreaterThan(int $idName, {bool include = false}) {
      return addWhereClauseInternal(
        IdWhereClause.greaterThan(lower: $idName, includeLower: include),
      );
    }
    ''';
  }

  String generateWhereGreaterThan(
      String indexName, List<ObjectIndexProperty> properties) {
    final name = joinToName(properties, true) + 'GreaterThan';
    if (!existing.add(name)) return '';

    final include =
        !properties.containsFloat ? ', {bool include = false,}' : '';
    return '''
    $mPrefix $name(${joinToParams(properties)} $include) {
      return addWhereClauseInternal(IndexWhereClause.greaterThan(
        indexName: '${indexName.esc}',
        lower: [${joinToValues(properties)}],
        includeLower: ${!properties.containsFloat ? 'include' : 'false'},
      ));
    }
    ''';
  }

  String generateWhereIdLessThan() {
    final idName = id.dartName.decapitalize();
    return '''
    $mPrefix ${idName}LessThan(int $idName, {bool include = false}) {
      return addWhereClauseInternal(
        IdWhereClause.lessThan(upper: $idName, includeUpper: include),
      );
    }
    ''';
  }

  String generateWhereLessThan(
      String indexName, List<ObjectIndexProperty> properties) {
    final name = joinToName(properties, true) + 'LessThan';
    if (!existing.add(name)) return '';

    final include =
        !properties.containsFloat ? ', {bool include = false,}' : '';
    return '''
    $mPrefix $name(${joinToParams(properties)} $include) {
      return addWhereClauseInternal(IndexWhereClause.lessThan(
        indexName: '${indexName.esc}',
        upper: [${joinToValues(properties)}],
        includeUpper: ${!properties.containsFloat ? 'include' : 'false'},
      ));
    }
    ''';
  }

  String generateWhereIdBetween() {
    final idName = id.dartName.decapitalize();
    final lowerName = 'lower${id.dartName.capitalize()}';
    final upperName = 'upper${id.dartName.capitalize()}';
    return '''
    $mPrefix ${idName}Between(int $lowerName,int $upperName, {bool includeLower = true, bool includeUpper = true,}) {
      return addWhereClauseInternal(IdWhereClause.between(
        lower: $lowerName,
        includeLower: includeLower,
        upper: $upperName,
        includeUpper: includeUpper,
      ));
    }
  ''';
  }

  String generateWhereBetween(
      String indexName, List<ObjectIndexProperty> properties) {
    final firstPs = properties.sublist(0, properties.length - 1);
    final lastP = properties.last;
    final name = joinToName(properties, true) + 'Between';
    if (!existing.add(name)) return '';

    var params = joinToParams(firstPs);
    if (params.isNotEmpty) {
      params += ',';
    }

    final lowerName = 'lower${paramName(lastP).capitalize()}';
    final upperName = 'upper${paramName(lastP).capitalize()}';
    params += '${paramType(lastP)} $lowerName, ${paramType(lastP)} $upperName';

    var values = joinToValues(firstPs);
    if (values.isNotEmpty) {
      values += ',';
    }

    final include = !properties.containsFloat
        ? ', {bool includeLower = true, bool includeUpper = true,}'
        : '';
    return '''
    $mPrefix $name($params $include) {
      return addWhereClauseInternal(IndexWhereClause.between(
        indexName: '${indexName.esc}',
        lower: [$values $lowerName],
        includeLower: ${!properties.containsFloat ? 'includeLower' : 'false'},
        upper: [$values $upperName],
        includeUpper: ${!properties.containsFloat ? 'includeUpper' : 'false'},
      ));
    }
  ''';
  }

  String generateWhereIsNull(
      String indexName, ObjectIndexProperty indexProperty) {
    final name = joinToName([indexProperty], false) + 'IsNull';
    if (!existing.add(name)) return '';

    return '''
    $mPrefix $name() {
      return addWhereClauseInternal(const IndexWhereClause.equalTo(
        indexName: '${indexName.esc}',
        value: [null],
      ));
    }
    ''';
  }

  String generateWhereIsNotNull(
      String indexName, ObjectIndexProperty indexProperty) {
    final name = joinToName([indexProperty], false) + 'IsNotNull';
    if (!existing.add(name)) return '';

    return '''
    $mPrefix $name() {
      return addWhereClauseInternal(const IndexWhereClause.greaterThan(
        indexName: '${indexName.esc}',
        lower: [null],
        includeLower: false,
      ));
    }
    ''';
  }

  String generateWhereStartsWith(
      String indexName, List<ObjectIndexProperty> properties) {
    final firsPs = properties.sublist(0, properties.length - 1);
    final lastP = properties.last;
    final name = joinToName(properties, true) + 'StartsWith';
    if (!existing.add(name)) return '';

    var params = joinToParams(firsPs);
    if (params.isNotEmpty) {
      params += ',';
    }
    final lastName = '${paramName(lastP).capitalize()}Prefix';
    params += '${paramType(lastP)} $lastName';
    var values = joinToValues(firsPs);
    if (values.isNotEmpty) {
      values += ',';
    }

    return '''
    $mPrefix $name($params) {
      return addWhereClauseInternal(IndexWhereClause.between(
        indexName: '${indexName.esc}',
        lower: [$values $lastName],
        includeLower: true,
        upper: [$values '\$$lastName\\u{FFFFF}'],
        includeUpper: true,
      ));
    }
    ''';
  }
}

extension on List<ObjectIndexProperty> {
  bool get containsFloat => last.isarType.containsFloat;
}
