import 'package:isar/src/generator/helper.dart';
import 'package:isar/src/generator/isar_type.dart';
import 'package:isar/src/generator/object_info.dart';

class FilterGenerator {
  FilterGenerator(this.object) : objName = object.dartName;
  final ObjectInfo object;
  final String objName;

  String generate() {
    var code =
        'extension ${objName}QueryFilter on QueryBuilder<$objName, $objName, '
        'QFilterCondition> {';
    for (final property in object.properties) {
      if (property.nullable) {
        code += generateIsNull(property);
        code += generateIsNotNull(property);
      }
      if ((property.elementNullable ?? false) && !property.type.isObject) {
        code += generateElementIsNull(property);
        code += generateElementIsNotNull(property);
      }

      if (!property.type.isObject) {
        code += generateEqualTo(property);

        if (!property.type.isBool) {
          code += generateGreaterThan(property);
          code += generateLessThan(property);
          code += generateBetween(property);
        }
      }

      if (property.type.isString) {
        code += generateStringStartsWith(property);
        code += generateStringEndsWith(property);
        code += generateStringContains(property);
        code += generateStringMatches(property);
        code += generateStringIsEmpty(property);
        code += generateStringIsNotEmpty(property);
      }

      if (property.type.isList) {
        //code += generateListLength(property);
      }
    }
    return '''
    $code
  }''';
  }

  String mPrefix(PropertyInfo p, [bool listElement = true]) {
    final any = listElement && p.type.isList ? 'Element' : '';
    return 'QueryBuilder<$objName, $objName, QAfterFilterCondition> '
        '${p.dartName.decapitalize()}$any';
  }

  String nullValue(PropertyInfo p) {
    return switch (p.type) {
      PropertyType.bool || PropertyType.boolList => 'Filter.nullBool',
      PropertyType.byte ||
      PropertyType.byteList ||
      PropertyType.int ||
      PropertyType.intList ||
      PropertyType.long ||
      PropertyType.longList ||
      PropertyType.dateTime ||
      PropertyType.dateTimeList =>
        'Filter.nullInt',
      PropertyType.float ||
      PropertyType.floatList ||
      PropertyType.double ||
      PropertyType.doubleList =>
        'Filter.nullDouble',
      PropertyType.string || PropertyType.stringList => 'Filter.nullString',
      PropertyType.object || PropertyType.objectList => throw ArgumentError(),
    };
  }

  String valOrNull(PropertyInfo p, String value) {
    if (p.elementNullable ?? p.nullable) {
      return '$value ?? ${nullValue(p)}';
    } else {
      return value;
    }
  }

  String generateEqualTo(PropertyInfo p) {
    final optional = [
      if (p.type.isString) 'bool caseSensitive = true',
      if (p.type.isFloat) 'double epsilon = Filter.epsilon',
    ].join(',');
    return '''
    ${mPrefix(p)}EqualTo(${p.scalarDartType} value ${optional.isNotEmpty ? ', {$optional,}' : ''}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(EqualToCondition(
          property: ${p.index},
          value: ${valOrNull(p, 'value')},
          ${p.type.isString ? 'caseSensitive: caseSensitive,' : ''}
          ${p.type.isFloat ? 'epsilon: epsilon,' : ''}
        ));
      });
    }''';
  }

  String generateGreaterThan(PropertyInfo p) {
    final optional = [
      'bool include = false',
      if (p.type.isString) 'bool caseSensitive = true',
      if (p.type.isFloat) 'double epsilon = Filter.epsilon',
    ].join(',');
    return '''
    ${mPrefix(p)}GreaterThan(${p.scalarDartType} value, {$optional,}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(GreaterThanCondition(
          include: include,
          property: ${p.index},
          value: ${valOrNull(p, 'value')},
          ${p.type.isString ? 'caseSensitive: caseSensitive,' : ''}
           ${p.type.isFloat ? 'epsilon: epsilon,' : ''}
        ));
      });
    }''';
  }

  String generateLessThan(PropertyInfo p) {
    final optional = [
      'bool include = false',
      if (p.type.isString) 'bool caseSensitive = true',
      if (p.type.isFloat) 'double epsilon = Filter.epsilon',
    ].join(',');
    return '''
    ${mPrefix(p)}LessThan(${p.scalarDartType} value, {$optional,}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(LessThanCondition(
          include: include,
          property: ${p.index},
          value: ${valOrNull(p, 'value')},
          ${p.type.isString ? 'caseSensitive: caseSensitive,' : ''}
           ${p.type.isFloat ? 'epsilon: epsilon,' : ''}
        ));
      });
    }''';
  }

  String generateBetween(PropertyInfo p) {
    final optional = [
      'bool includeLower = true',
      'bool includeUpper = true',
      if (p.type.isString) 'bool caseSensitive = true',
      if (p.type.isFloat) 'double epsilon = Filter.epsilon',
    ].join(',');
    return '''
    ${mPrefix(p)}Between(${p.scalarDartType} lower, ${p.scalarDartType} upper, {$optional,}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(BetweenCondition(
          property: ${p.index},
          lower: ${valOrNull(p, 'lower')},
          includeLower: includeLower,
          upper: ${valOrNull(p, 'upper')},
          includeUpper: includeUpper,
          ${p.type.isString ? 'caseSensitive: caseSensitive,' : ''}
           ${p.type.isFloat ? 'epsilon: epsilon,' : ''}
        ));
      });
    }''';
  }

  String generateIsNull(PropertyInfo p) {
    return '''
      ${mPrefix(p, false)}IsNull() {
        return QueryBuilder.apply(this, (query) {
          return query.addFilterCondition(const IsNullCondition(property: ${p.index}));
        });
      }''';
  }

  String generateElementIsNull(PropertyInfo p) {
    return '''
      ${mPrefix(p)}IsNull() {
        return QueryBuilder.apply(this, (query) {
          return query.addFilterCondition(const EqualToCondition(
            property: ${p.index},
            value: ${nullValue(p)}
          ));
        });
      }''';
  }

  String generateIsNotNull(PropertyInfo p) {
    return '''
      ${mPrefix(p, false)}IsNotNull() {
        return QueryBuilder.apply(not(), (query) {
          return query.addFilterCondition(const IsNullCondition(property: ${p.index}));
        });
      }''';
  }

  String generateElementIsNotNull(PropertyInfo p) {
    return '''
      ${mPrefix(p)}IsNotNull() {
        return QueryBuilder.apply(not(), (query) {
          return query
            .addFilterCondition(const EqualToCondition(
              property: ${p.index}, 
              value: ${nullValue(p)}
            ));
        });
      }''';
  }

  String generateStringStartsWith(PropertyInfo p) {
    return '''
    ${mPrefix(p)}StartsWith(String value, {bool caseSensitive = true,}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(StartsWithCondition(
          property: ${p.index},
          value: value,
          caseSensitive: caseSensitive,
        ));
      });
    }''';
  }

  String generateStringEndsWith(PropertyInfo p) {
    return '''
    ${mPrefix(p)}EndsWith(String value, {bool caseSensitive = true,}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(EndsWithCondition(
          property: ${p.index},
          value: value,
          caseSensitive: caseSensitive,
        ));
      });
    }''';
  }

  String generateStringContains(PropertyInfo p) {
    return '''
    ${mPrefix(p)}Contains(String value, {bool caseSensitive = true}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(ContainsCondition(
          property: ${p.index},
          value: value,
          caseSensitive: caseSensitive,
        ));
      });
    }''';
  }

  String generateStringMatches(PropertyInfo p) {
    return '''
    ${mPrefix(p)}Matches(String pattern, {bool caseSensitive = true}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(MatchesCondition(
          property: ${p.index},
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ));
      });
    }''';
  }

  String generateStringIsEmpty(PropertyInfo p) {
    return '''
    ${mPrefix(p)}IsEmpty() {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(EqualToCondition(
          property: ${p.index},
          value: '',
        ));
      });
    }''';
  }

  String generateStringIsNotEmpty(PropertyInfo p) {
    return '''
    ${mPrefix(p)}IsNotEmpty() {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(GreaterThanCondition(
          property: ${p.index},
          value: '',
        ));
      });
    }''';
  }

  /*String generateListLength(PropertyInfo p) {
    return generateLength(objName, p.dartName,
        (lower, includeLower, upper, includeUpper) {
      return '''
        QueryBuilder.apply(this, (query) {
          return query.listLength(
            r'${p.isarName}',
            $lower,
            $includeLower,
            $upper,
            $includeUpper,
          );
        })''';
    });
  }*/
}
