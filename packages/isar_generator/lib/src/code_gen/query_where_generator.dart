import 'package:dartx/dartx.dart';
import 'package:isar/isar.dart';

import 'package:isar_generator/src/isar_type.dart';
import 'package:isar_generator/src/object_info.dart';

class WhereGenerator {
  WhereGenerator(this.object)
      : objName = object.dartName,
        id = object.idProperty;
  final ObjectInfo object;
  final String objName;
  final ObjectProperty id;
  final existing = <String>{};

  String generate() {
    var code = 'extension ${objName}QueryWhereSort on QueryBuilder<$objName, '
        '$objName, QWhere> {';

    code += generateAnyId();
    for (final index in object.indexes) {
      if (index.properties.all((element) => element.type == IndexType.value)) {
        code += generateAny(index);
      }
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

    for (final index in object.indexes) {
      for (var n = 0; n < index.properties.length; n++) {
        final property = index.properties[n];

        if (!property.property.isarType.containsFloat) {
          code += generateWhereEqualTo(index, n + 1);
          code += generateWhereNotEqualTo(index, n + 1);
        }

        if (property.property.nullable) {
          code += generateWhereIsNull(index, n + 1);
          code += generateWhereIsNotNull(index, n + 1);
        }

        if (property.type != IndexType.hash) {
          if (property.scalarType != IsarType.bool) {
            code += generateWhereGreaterThan(index, n + 1);
            code += generateWhereLessThan(index, n + 1);
            code += generateWhereBetween(index, n + 1);
          }

          if (property.scalarType == IsarType.string) {
            code += generateWhereStartsWith(index, n + 1);
          }
        }

        if (property.property.isarType.containsFloat) {
          break;
        }
      }
    }

    return '$code}';
  }

  String getMethodName(ObjectIndex index, int propertyCount, [String? method]) {
    String propertyName(ObjectIndexProperty p) {
      var name = p.property.dartName.capitalize();
      if (p.isMultiEntry) {
        name += 'Element';
      }
      return name;
    }

    var name = '';
    final eqProperties =
        index.properties.sublist(0, propertyCount - (method != null ? 1 : 0));
    if (eqProperties.isNotEmpty) {
      name += eqProperties.map(propertyName).join();
      name += 'EqualTo';
    }

    if (method != null) {
      name += propertyName(index.properties[propertyCount - 1]);
      name += method;
    }

    final remainingProperties = propertyCount < index.properties.length
        ? index.properties.sublist(propertyCount)
        : null;

    if (remainingProperties != null) {
      name += 'Any';
      name += remainingProperties.map(propertyName).join();
    }

    return name.decapitalize();
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
        return it.property.toIsar(paramName(it), object);
      }
    }).join(', ');
  }

  String generateAnyId() {
    return '''
    QueryBuilder<$objName, $objName, QAfterWhere> any${id.dartName.capitalize()}() {
      return QueryBuilder.apply(this, (query) {
        return query.addWhereClause(const IdWhereClause.any());
      });
    }
    ''';
  }

  String generateAny(ObjectIndex index) {
    final name = getMethodName(index, 0);
    if (!existing.add(name)) {
      return '';
    }
    return '''
    QueryBuilder<$objName, $objName, QAfterWhere> $name() {
      return QueryBuilder.apply(this, (query) {
        return query.addWhereClause(
          const IndexWhereClause.any(indexName: r'${index.name}'),
        );
      });
    }
    ''';
  }

  String get mPrefix => 'QueryBuilder<$objName, $objName, QAfterWhereClause>';

  String generateWhereIdEqualTo() {
    final idName = id.dartName.decapitalize();
    return '''
    $mPrefix ${idName}EqualTo(int $idName) {
      return QueryBuilder.apply(this, (query) {
        return query.addWhereClause(IdWhereClause.between(
          lower: $idName,
          upper: $idName,
        ));
      });
    }
    ''';
  }

  String generateWhereEqualTo(ObjectIndex index, int propertyCount) {
    final name = getMethodName(index, propertyCount);
    if (!existing.add(name)) {
      return '';
    }

    final properties = index.properties.takeFirst(propertyCount);
    final values = joinToValues(properties);
    final params = joinToParams(properties);
    return '''
    $mPrefix $name($params) {
      return QueryBuilder.apply(this, (query) {
        return query.addWhereClause(IndexWhereClause.equalTo(
          indexName: r'${index.name}',
          value: [$values],
        ));
      });
    }
    ''';
  }

  String generateWhereIdNotEqualTo() {
    final idName = id.dartName.decapitalize();
    return '''
    $mPrefix ${idName}NotEqualTo(int $idName) {
      return QueryBuilder.apply(this, (query) {
        if (query.whereSort == Sort.asc) {
          return query.addWhereClause(
            IdWhereClause.lessThan(upper: $idName, includeUpper: false),
          ).addWhereClause(
            IdWhereClause.greaterThan(lower: $idName, includeLower: false),
          );
        } else {
          return query.addWhereClause(
            IdWhereClause.greaterThan(lower: $idName, includeLower: false),
          ).addWhereClause(
            IdWhereClause.lessThan(upper: $idName, includeUpper: false),
          );
        }
      });
    }
    ''';
  }

  String generateWhereNotEqualTo(ObjectIndex index, int propertyCount) {
    final name = getMethodName(index, propertyCount, 'NotEqualTo');
    if (!existing.add(name)) {
      return '';
    }

    final properties = index.properties.takeFirst(propertyCount);
    final params = joinToParams(properties);

    final equalProperties = properties.dropLast(1);
    final notEqualProperty = properties.last;
    final equalValues = joinToValues(equalProperties);
    var notEqualValue = joinToValues([notEqualProperty]);
    if (equalValues.isNotEmpty) {
      notEqualValue = ',$notEqualValue';
    }

    return '''
    $mPrefix $name($params) {
      return QueryBuilder.apply(this, (query) {
        if (query.whereSort == Sort.asc) {
          return query.addWhereClause(IndexWhereClause.between(
            indexName: r'${index.name}',
            lower: [$equalValues],
            upper: [$equalValues $notEqualValue],
            includeUpper: false,
          )).addWhereClause(IndexWhereClause.between(
            indexName: r'${index.name}',
            lower: [$equalValues $notEqualValue],
            includeLower: false,
            upper: [$equalValues],
          ));
        } else {
          return query.addWhereClause(IndexWhereClause.between(
            indexName: r'${index.name}',
            lower: [$equalValues $notEqualValue],
            includeLower: false,
            upper: [$equalValues],
          )).addWhereClause(IndexWhereClause.between(
            indexName: r'${index.name}',
            lower: [$equalValues],
            upper: [$equalValues $notEqualValue],
            includeUpper: false,
          ));
        }
      });
    }
    ''';
  }

  String generateWhereIdGreaterThan() {
    final idName = id.dartName.decapitalize();
    return '''
    $mPrefix ${idName}GreaterThan(int $idName, {bool include = false}) {
      return QueryBuilder.apply(this, (query) {
        return query.addWhereClause(
          IdWhereClause.greaterThan(lower: $idName, includeLower: include),
        );
      });
    }
    ''';
  }

  String generateWhereGreaterThan(ObjectIndex index, int propertyCount) {
    final name = getMethodName(index, propertyCount, 'GreaterThan');
    if (!existing.add(name)) {
      return '';
    }

    final properties = index.properties.takeFirst(propertyCount);
    final include =
        !properties.containsFloat ? ', {bool include = false,}' : '';
    return '''
    $mPrefix $name(${joinToParams(properties)} $include) {
      return QueryBuilder.apply(this, (query) {
        return query.addWhereClause(IndexWhereClause.between(
          indexName: r'${index.name}',
          lower: [${joinToValues(properties)}],
          includeLower: ${!properties.containsFloat ? 'include' : 'false'},
          upper: [${joinToValues(properties.dropLast(1))}],
        ));
      });
    }
    ''';
  }

  String generateWhereIdLessThan() {
    final idName = id.dartName.decapitalize();
    return '''
    $mPrefix ${idName}LessThan(int $idName, {bool include = false}) {
      return QueryBuilder.apply(this, (query) {
        return query.addWhereClause(
          IdWhereClause.lessThan(upper: $idName, includeUpper: include),
        );
      });
    }
    ''';
  }

  String generateWhereLessThan(ObjectIndex index, int propertyCount) {
    final name = getMethodName(index, propertyCount, 'LessThan');
    if (!existing.add(name)) {
      return '';
    }

    final properties = index.properties.takeFirst(propertyCount);
    final include =
        !properties.containsFloat ? ', {bool include = false,}' : '';
    return '''
    $mPrefix $name(${joinToParams(properties)} $include) {
      return QueryBuilder.apply(this, (query) {
        return query.addWhereClause(IndexWhereClause.between(
          indexName: r'${index.name}',
          lower: [${joinToValues(properties.dropLast(1))}],
          upper: [${joinToValues(properties)}],
          includeUpper: ${!properties.containsFloat ? 'include' : 'false'},
        ));
      });
    }
    ''';
  }

  String generateWhereIdBetween() {
    final idName = id.dartName.decapitalize();
    final lowerName = 'lower${id.dartName.capitalize()}';
    final upperName = 'upper${id.dartName.capitalize()}';
    return '''
    $mPrefix ${idName}Between(int $lowerName,int $upperName, {bool includeLower = true, bool includeUpper = true,}) {
      return QueryBuilder.apply(this, (query) {
        return query.addWhereClause(IdWhereClause.between(
          lower: $lowerName,
          includeLower: includeLower,
          upper: $upperName,
          includeUpper: includeUpper,
        ));
      });
    }
  ''';
  }

  String generateWhereBetween(ObjectIndex index, int propertyCount) {
    final name = getMethodName(index, propertyCount, 'Between');
    if (!existing.add(name)) {
      return '';
    }

    final properties = index.properties.takeFirst(propertyCount);
    final equalProperties = properties.dropLast(1);
    final betweenProperty = properties.last;
    var params = joinToParams(equalProperties);
    if (params.isNotEmpty) {
      params += ',';
    }

    final betweenType = paramType(betweenProperty);
    final lowerName = 'lower${paramName(betweenProperty).capitalize()}';
    final upperName = 'upper${paramName(betweenProperty).capitalize()}';
    params += '$betweenType $lowerName, $betweenType $upperName';

    var values = joinToValues(equalProperties);
    if (values.isNotEmpty) {
      values += ',';
    }

    final float = properties.containsFloat;
    final include =
        !float ? ', {bool includeLower = true, bool includeUpper = true,}' : '';
    return '''
    $mPrefix $name($params $include) {
      return QueryBuilder.apply(this, (query) {
        return query.addWhereClause(IndexWhereClause.between(
          indexName: r'${index.name}',
          lower: [$values $lowerName],
          includeLower: ${!float ? 'includeLower' : 'false'},
          upper: [$values $upperName],
          includeUpper: ${!float ? 'includeUpper' : 'false'},
        ));
      });
    }
  ''';
  }

  String generateWhereIsNull(ObjectIndex index, int propertyCount) {
    final name = getMethodName(index, propertyCount, 'IsNull');
    if (!existing.add(name)) {
      return '';
    }

    final properties = index.properties.takeFirst(propertyCount - 1);
    var values = joinToValues(properties);
    if (values.isNotEmpty) {
      values += ',';
    }
    final params = joinToParams(properties);
    return '''
    $mPrefix $name($params) {
      return QueryBuilder.apply(this, (query) {
        return query.addWhereClause(IndexWhereClause.equalTo(
          indexName: r'${index.name}',
          value: [$values null],
        ));
      });
    }
    ''';
  }

  String generateWhereIsNotNull(ObjectIndex index, int propertyCount) {
    final name = getMethodName(index, propertyCount, 'IsNotNull');
    if (!existing.add(name)) {
      return '';
    }

    final properties = index.properties.takeFirst(propertyCount - 1);
    var values = joinToValues(properties);
    if (values.isNotEmpty) {
      values += ',';
    }
    final params = joinToParams(properties);
    return '''
    $mPrefix $name($params) {
      return QueryBuilder.apply(this, (query) {
        return query.addWhereClause(IndexWhereClause.between(
          indexName: r'${index.name}',
          lower: [$values null],
          includeLower: false,
          upper: [$values],
        ));
      });
    }
    ''';
  }

  String generateWhereStartsWith(ObjectIndex index, int propertyCount) {
    final name = getMethodName(index, propertyCount, 'StartsWith');
    if (!existing.add(name)) {
      return '';
    }

    final equalProperties = index.properties.dropLast(1);
    final prefixProperty = index.properties.last;
    var params = joinToParams(equalProperties);
    if (params.isNotEmpty) {
      params += ',';
    }
    final prefixName = '${paramName(prefixProperty).capitalize()}Prefix';
    params += '${paramType(prefixProperty)} $prefixName';
    var values = joinToValues(equalProperties);
    if (values.isNotEmpty) {
      values += ',';
    }

    return '''
    $mPrefix $name($params) {
      return QueryBuilder.apply(this, (query) {
        return query.addWhereClause(IndexWhereClause.between(
          indexName: r'${index.name}',
          lower: [$values $prefixName],
          upper: [$values '\$$prefixName\\u{FFFFF}'],
        ));
      });
    }
    ''';
  }
}

extension on List<ObjectIndexProperty> {
  bool get containsFloat => last.isarType.containsFloat;
}
