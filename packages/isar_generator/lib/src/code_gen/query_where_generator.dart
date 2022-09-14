import 'package:dartx/dartx.dart';
import 'package:isar/isar.dart';
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
        final indexProperty = index.properties[n];
        final property = indexProperty.property;

        if ((property.nullable && !indexProperty.isMultiEntry) ||
            (property.elementNullable && indexProperty.isMultiEntry)) {
          code += generateWhereIsNull(index, n + 1);
          code += generateWhereIsNotNull(index, n + 1);
        }

        code += generateWhereEqualTo(index, n + 1);
        code += generateWhereNotEqualTo(index, n + 1);

        if (indexProperty.type == IndexType.value) {
          if (property.isarType != IsarType.bool &&
              property.isarType != IsarType.boolList) {
            code += generateWhereGreaterThan(index, n + 1);
            code += generateWhereLessThan(index, n + 1);
            code += generateWhereBetween(index, n + 1);
          }

          if (property.isarType == IsarType.string ||
              property.isarType == IsarType.stringList) {
            code += generateWhereStartsWith(index, n + 1);
            code += generateStringIsEmpty(index, n + 1);
            code += generateStringIsNotEmpty(index, n + 1);
          }
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
    if (p.property.isarType.isList && p.type == IndexType.hash) {
      return p.property.dartType;
    } else {
      return p.property.nScalarDartType;
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
        return paramName(it);
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
    $mPrefix ${idName}EqualTo(Id $idName) {
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
    $mPrefix $name($params ${properties.containsFloat ? ', {double epsilon = Query.epsilon,}' : ''}) {
      return QueryBuilder.apply(this, (query) {
        return query.addWhereClause(IndexWhereClause.equalTo(
          indexName: r'${index.name}',
          value: [$values],
          ${properties.containsFloat ? 'epsilon: epsilon,' : ''}
        ));
      });
    }
    ''';
  }

  String generateWhereIdNotEqualTo() {
    final idName = id.dartName.decapitalize();
    return '''
    $mPrefix ${idName}NotEqualTo(Id $idName) {
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
    $mPrefix $name($params ${properties.containsFloat ? ', {double epsilon = Query.epsilon,}' : ''}) {
      return QueryBuilder.apply(this, (query) {
        if (query.whereSort == Sort.asc) {
          return query.addWhereClause(IndexWhereClause.between(
            indexName: r'${index.name}',
            lower: [$equalValues],
            upper: [$equalValues $notEqualValue],
            includeUpper: false,
            ${properties.containsFloat ? 'epsilon: epsilon,' : ''}
          )).addWhereClause(IndexWhereClause.between(
            indexName: r'${index.name}',
            lower: [$equalValues $notEqualValue],
            includeLower: false,
            upper: [$equalValues],
            ${properties.containsFloat ? 'epsilon: epsilon,' : ''}
          ));
        } else {
          return query.addWhereClause(IndexWhereClause.between(
            indexName: r'${index.name}',
            lower: [$equalValues $notEqualValue],
            includeLower: false,
            upper: [$equalValues],
            ${properties.containsFloat ? 'epsilon: epsilon,' : ''}
          )).addWhereClause(IndexWhereClause.between(
            indexName: r'${index.name}',
            lower: [$equalValues],
            upper: [$equalValues $notEqualValue],
            includeUpper: false,
            ${properties.containsFloat ? 'epsilon: epsilon,' : ''}
          ));
        }
      });
    }
    ''';
  }

  String generateWhereIdGreaterThan() {
    final idName = id.dartName.decapitalize();
    return '''
    $mPrefix ${idName}GreaterThan(Id $idName, {bool include = false}) {
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
    final optional = [
      'bool include = false',
      if (properties.containsFloat) 'double epsilon = Query.epsilon',
    ].join(',');
    return '''
    $mPrefix $name(${joinToParams(properties)}, {$optional,}) {
      return QueryBuilder.apply(this, (query) {
        return query.addWhereClause(IndexWhereClause.between(
          indexName: r'${index.name}',
          lower: [${joinToValues(properties)}],
          includeLower: include,
          upper: [${joinToValues(properties.dropLast(1))}],
          ${properties.containsFloat ? 'epsilon: epsilon,' : ''}
        ));
      });
    }
    ''';
  }

  String generateWhereIdLessThan() {
    final idName = id.dartName.decapitalize();
    return '''
    $mPrefix ${idName}LessThan(Id $idName, {bool include = false}) {
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
    final optional = [
      'bool include = false',
      if (properties.containsFloat) 'double epsilon = Query.epsilon',
    ].join(',');
    return '''
    $mPrefix $name(${joinToParams(properties)}, {$optional,}) {
      return QueryBuilder.apply(this, (query) {
        return query.addWhereClause(IndexWhereClause.between(
          indexName: r'${index.name}',
          lower: [${joinToValues(properties.dropLast(1))}],
          upper: [${joinToValues(properties)}],
          includeUpper: include,
          ${properties.containsFloat ? 'epsilon: epsilon,' : ''}
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
    $mPrefix ${idName}Between(Id $lowerName, Id $upperName, {bool includeLower = true, bool includeUpper = true,}) {
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

    final optional = [
      'bool includeLower = true',
      'bool includeUpper = true',
      if (properties.containsFloat) 'double epsilon = Query.epsilon',
    ].join(',');
    return '''
    $mPrefix $name($params, {$optional,}) {
      return QueryBuilder.apply(this, (query) {
        return query.addWhereClause(IndexWhereClause.between(
          indexName: r'${index.name}',
          lower: [$values $lowerName],
          includeLower: includeLower,
          upper: [$values $upperName],
          includeUpper: includeUpper,
          ${properties.containsFloat ? 'epsilon: epsilon,' : ''}
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
    var params = joinToParams(equalProperties);
    if (params.isNotEmpty) {
      params += ',';
    }

    final prefixProperty = index.properties.last;
    final prefixName = '${paramName(prefixProperty).capitalize()}Prefix';
    params += 'String $prefixName';
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

  String generateStringIsEmpty(ObjectIndex index, int propertyCount) {
    final name = getMethodName(index, propertyCount, 'IsEmpty');
    if (!existing.add(name)) {
      return '';
    }

    final properties = index.properties.dropLast(1);
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
          value: [$values ''],
        ));
      });
    }''';
  }

  String generateStringIsNotEmpty(ObjectIndex index, int propertyCount) {
    final name = getMethodName(index, propertyCount, 'IsNotEmpty');
    if (!existing.add(name)) {
      return '';
    }

    final properties = index.properties.dropLast(1);
    var values = joinToValues(properties);
    if (values.isNotEmpty) {
      values += ',';
    }
    final params = joinToParams(properties);

    return '''
    $mPrefix $name($params) {
      return QueryBuilder.apply(this, (query) {
        if (query.whereSort == Sort.asc) {
          return query.addWhereClause(IndexWhereClause.lessThan(
            indexName: r'${index.name}',
            upper: [''],
          )).addWhereClause(IndexWhereClause.greaterThan(
            indexName: r'${index.name}',
            lower: [''],
          ));
        } else {
          return query.addWhereClause(IndexWhereClause.greaterThan(
            indexName: r'${index.name}',
            lower: [''],
          )).addWhereClause(IndexWhereClause.lessThan(
            indexName: r'${index.name}',
            upper: [''],
          ));
        }
      });
    }''';
  }
}

extension on List<ObjectIndexProperty> {
  bool get containsFloat =>
      last.isarType == IsarType.float || last.isarType == IsarType.floatList;
}
