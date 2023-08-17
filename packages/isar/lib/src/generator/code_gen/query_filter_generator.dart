part of isar_generator;

class _FilterGenerator {
  _FilterGenerator(this.object) : objName = object.dartName;

  final ObjectInfo object;
  final String objName;

  String generate() {
    var code =
        'extension ${objName}QueryFilter on QueryBuilder<$objName, $objName, '
        'QFilterCondition> {';
    for (final property in object.properties) {
      if (property.type == IsarType.json) {
        continue;
      }

      if (property.nullable) {
        code += generateIsNull(property);
        code += generateIsNotNull(property);
      }
      if ((property.elementNullable ?? false) && !property.type.isObject) {
        code += generateElementIsNull(property);
        code += generateElementIsNotNull(property);
      }

      if (!property.type.isObject) {
        code += generateEqual(property);

        if (!property.type.isBool) {
          code += generateGreater(property);
          code += generateLess(property);
          code += generateBetween(property);
        }
      }

      if (property.type.isString && !property.isEnum) {
        code += generateStringStartsWith(property);
        code += generateStringEndsWith(property);
        code += generateStringContains(property);
        code += generateStringMatches(property);
        code += generateStringIsEmpty(property);
        code += generateStringIsNotEmpty(property);
      }

      if (property.type.isList) {
        code += generateListIsEmpty(property);
        code += generateListIsNotEmpty(property);
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

  String optional(List<String> parameters) {
    if (parameters.isNotEmpty) {
      return '{${parameters.join(',')},}';
    } else {
      return '';
    }
  }

  String value(String name, PropertyInfo p) {
    if (p.enumProperty != null) {
      final nullable = p.elementNullable ?? p.nullable;
      return '$name${nullable ? '?' : ''}.${p.enumProperty}';
    } else {
      return name;
    }
  }

  String generateEqual(PropertyInfo p) {
    final optionalParams = optional([
      if (p.type.isString && !p.isEnum) 'bool caseSensitive = true',
      if (p.type.isFloat) 'double epsilon = Filter.epsilon',
    ]);
    return '''
    ${mPrefix(p)}EqualTo(${p.scalarDartType} value, $optionalParams) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(
          EqualCondition(
            property: ${p.index},
            value: ${value('value', p)},
            ${p.type.isString && !p.isEnum ? 'caseSensitive: caseSensitive,' : ''}
            ${p.type.isFloat ? 'epsilon: epsilon,' : ''}
          ),
        );
      });
    }''';
  }

  String generateGreater(PropertyInfo p) {
    final optionalParams = optional([
      if (p.type.isString && !p.isEnum) 'bool caseSensitive = true',
      if (p.type.isFloat) 'double epsilon = Filter.epsilon',
    ]);
    return '''
    ${mPrefix(p)}GreaterThan(${p.scalarDartType} value, $optionalParams) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(
          GreaterCondition(
            property: ${p.index},
            value: ${value('value', p)},
            ${p.type.isString && !p.isEnum ? 'caseSensitive: caseSensitive,' : ''}
            ${p.type.isFloat ? 'epsilon: epsilon,' : ''}
          ),
        );
      });
    }
    
    ${mPrefix(p)}GreaterThanOrEqualTo(${p.scalarDartType} value, $optionalParams) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(
          GreaterOrEqualCondition(
            property: ${p.index},
            value: ${value('value', p)},
            ${p.type.isString && !p.isEnum ? 'caseSensitive: caseSensitive,' : ''}
            ${p.type.isFloat ? 'epsilon: epsilon,' : ''}
          ),
        );
      });
    }
    ''';
  }

  String generateLess(PropertyInfo p) {
    final optionalParams = optional([
      if (p.type.isString && !p.isEnum) 'bool caseSensitive = true',
      if (p.type.isFloat) 'double epsilon = Filter.epsilon',
    ]);
    return '''
    ${mPrefix(p)}LessThan(${p.scalarDartType} value, $optionalParams) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(
          LessCondition(
            property: ${p.index},
            value: ${value('value', p)},
            ${p.type.isString && !p.isEnum ? 'caseSensitive: caseSensitive,' : ''}
            ${p.type.isFloat ? 'epsilon: epsilon,' : ''}
          ),
        );
      });
    }
    
    ${mPrefix(p)}LessThanOrEqualTo(${p.scalarDartType} value, $optionalParams) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(
          LessOrEqualCondition(
            property: ${p.index},
            value: ${value('value', p)},
            ${p.type.isString && !p.isEnum ? 'caseSensitive: caseSensitive,' : ''}
            ${p.type.isFloat ? 'epsilon: epsilon,' : ''}
          ),
        );
      });
    }''';
  }

  String generateBetween(PropertyInfo p) {
    final optionalParams = optional([
      if (p.type.isString && !p.isEnum) 'bool caseSensitive = true',
      if (p.type.isFloat) 'double epsilon = Filter.epsilon',
    ]);
    return '''
    ${mPrefix(p)}Between(${p.scalarDartType} lower, ${p.scalarDartType} upper, $optionalParams) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(
          BetweenCondition(
            property: ${p.index},
            lower: ${value('lower', p)},
            upper: ${value('upper', p)},
            ${p.type.isString && !p.isEnum ? 'caseSensitive: caseSensitive,' : ''}
            ${p.type.isFloat ? 'epsilon: epsilon,' : ''}
          ),
        );
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
          return query.addFilterCondition(
            const EqualCondition(
              property: ${p.index},
              value: null
            ),
          );
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
        return QueryBuilder.apply(this, (query) {
          return query.addFilterCondition(
            const GreaterCondition(
              property: ${p.index},
              value: null,
            ),
          );
        });
      }''';
  }

  String generateStringStartsWith(PropertyInfo p) {
    return '''
    ${mPrefix(p)}StartsWith(String value, {bool caseSensitive = true,}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(
          StartsWithCondition(
            property: ${p.index},
            value: value,
            caseSensitive: caseSensitive,
          ),
        );
      });
    }''';
  }

  String generateStringEndsWith(PropertyInfo p) {
    return '''
    ${mPrefix(p)}EndsWith(String value, {bool caseSensitive = true,}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(
          EndsWithCondition(
            property: ${p.index},
            value: value,
            caseSensitive: caseSensitive,
          ),
        );
      });
    }''';
  }

  String generateStringContains(PropertyInfo p) {
    return '''
    ${mPrefix(p)}Contains(String value, {bool caseSensitive = true}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(
          ContainsCondition(
            property: ${p.index},
            value: value,
            caseSensitive: caseSensitive,
          ),
        );
      });
    }''';
  }

  String generateStringMatches(PropertyInfo p) {
    return '''
    ${mPrefix(p)}Matches(String pattern, {bool caseSensitive = true}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(
          MatchesCondition(
            property: ${p.index},
            wildcard: pattern,
            caseSensitive: caseSensitive,
          ),
        );
      });
    }''';
  }

  String generateStringIsEmpty(PropertyInfo p) {
    return '''
    ${mPrefix(p)}IsEmpty() {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(
          const EqualCondition(
            property: ${p.index},
            value: '',
          ),
        );
      });
    }''';
  }

  String generateStringIsNotEmpty(PropertyInfo p) {
    return '''
    ${mPrefix(p)}IsNotEmpty() {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(
          const GreaterCondition(
            property: ${p.index},
            value: '',
          ),
        );
      });
    }''';
  }

  String generateListIsEmpty(PropertyInfo p) {
    final name = p.dartName.decapitalize();
    if (p.nullable) {
      return '''
      ${mPrefix(p, false)}IsEmpty() {
        return not().group((q) => q
          .${name}IsNull()
          .or()
          .${name}IsNotEmpty(),
        );
      }''';
    } else {
      return '''
      ${mPrefix(p, false)}IsEmpty() {
        return not().${name}IsNotEmpty();
      }''';
    }
  }

  String generateListIsNotEmpty(PropertyInfo p) {
    return '''
    ${mPrefix(p, false)}IsNotEmpty() {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(
          const GreaterOrEqualCondition(property: ${p.index}, value: null),
        );
      });
    }''';
  }
}
