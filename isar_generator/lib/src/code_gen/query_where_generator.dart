import 'package:isar_generator/src/object_info.dart';
import 'package:dartx/dartx.dart';

String generateQueryWhere(ObjectInfo object) {
  var whereSort = object.indices.mapIndexed((indexIndex, index) {
    var properties =
        index.properties.map((f) => object.getProperty(f)).toList();
    return generateSortedBy(indexIndex, object.type, properties);
  }).join('\n');

  var where = object.indices.mapIndexed((indexIndex, index) {
    var code = '';
    for (var n = 0; n < index.properties.length; n++) {
      var properties = index.properties
          .sublist(0, n + 1)
          .map((f) => object.getProperty(f))
          .toList();

      if (properties.all((it) => it.type != DataType.Double)) {
        code += generateWhereEqualTo(indexIndex, object.type, properties);
        code += generateWhereNotEqualTo(indexIndex, object.type, properties);
      }

      if (properties.length == 1) {
        var property = properties.first;

        if (property.type != DataType.Bool) {
          code += generateWhereBetween(indexIndex, object.type, property);
        }

        if (property.type != DataType.Double) {
          code += generateWhereAnyOf(object.type, property);
        }

        if (property.type == DataType.Int ||
            property.type == DataType.Long ||
            property.type == DataType.Float ||
            property.type == DataType.Double) {
          code += generateLowerThan(indexIndex, object.type, property);
          code += generateGreaterThan(indexIndex, object.type, property);
        }

        if (property.type == DataType.String && !index.hashValue) {
          code += generateWhereStartsWith(indexIndex, object.type, property);
        }
      }
    }
    return code;
  }).join('\n');

  return '''
  extension ${object.type}QueryWhereSort on QueryBuilder<${object.type}, 
    QNoWhere, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic> {
    $whereSort
  }
  
  extension ${object.type}QueryWhere on QueryBuilder<${object.type}, 
    QWhere, dynamic, dynamic, dynamic, dynamic, dynamic, dynamic> {
    $where
  }
  ''';
}

String joinPropertiesToName(List<ObjectProperty> properties) {
  return properties
      .mapIndexed(
          (i, f) => i == 0 ? f.name.decapitalize() : f.name.capitalize())
      .join('');
}

String joinPropertiesToParams(List<ObjectProperty> properties,
    {String suffix = '', bool nullable = false}) {
  return properties
      .map((it) =>
          '${it.type.toTypeName()}${nullable ? '?' : ''} ${it.name}$suffix')
      .join(',');
}

String joinPropertiesToList(List<ObjectProperty> properties,
    [String suffix = '']) {
  return '[' + properties.map((it) => it.name + suffix).join(', ') + ']';
}

String joinPropertiesToTypes(List<ObjectProperty> properties) {
  return '[' +
      properties
          .map((it) => '"' + it.type.toString().substring(9) + '"')
          .join(', ') +
      ']';
}

String whereReturnParams(String whereType) {
  return '$whereType, QCanFilter, QNoGroups, QCanGroupBy, QCanOffsetLimit, QCanSort, QCanExecute';
}

String whereReturn(String type, String whereType) {
  return 'QueryBuilder<$type, ${whereReturnParams(whereType)}>';
}

String generateSortedBy(
    int index, String type, List<ObjectProperty> properties) {
  final propertiesName = joinPropertiesToName(properties);
  return '''
  ${whereReturn(type, 'dynamic')} sortedBy${propertiesName.capitalize()}(/*[bool distinct = false]*/) {
    return addWhereClause(WhereClause($index, []));
  }
  ''';
}

String generateWhereEqualTo(
    int index, String type, List<ObjectProperty> properties) {
  final propertiesName = joinPropertiesToName(properties);
  final propertyTypes = joinPropertiesToTypes(properties);
  final propertiesList = joinPropertiesToList(properties);
  return '''
  ${whereReturn(type, 'QWhereProperty')} ${propertiesName}EqualTo(${joinPropertiesToParams(properties)}) {
    return addWhereClause(WhereClause(
      $index,
      $propertyTypes,
      upper: $propertiesList,
      includeUpper: true,
      lower: $propertiesList,
      includeLower: true,
    ));
  }
  ''';
}

String generateWhereNotEqualTo(
    int index, String type, List<ObjectProperty> properties) {
  final propertiesName = joinPropertiesToName(properties);
  final propertyTypes = joinPropertiesToTypes(properties);
  final propertiesList = joinPropertiesToList(properties);
  return '''
  ${whereReturn(type, 'QWhereProperty')} ${propertiesName}NotEqualTo(${joinPropertiesToParams(properties)}) {
    final cloned = addWhereClause(WhereClause(
      $index,
      $propertyTypes,
      upper: $propertiesList,
      includeUpper: false,
    ));
    return cloned.addWhereClause(WhereClause(
      $index,
      $propertyTypes,
      lower: $propertiesList,
      includeLower: false,
    ));
  }
  ''';
}

String generateLowerThan(int index, String type, ObjectProperty property) {
  final propertiesName = joinPropertiesToName([property]);
  final propertyTypes = joinPropertiesToTypes([property]);
  return '''
  ${whereReturn(type, 'QWhereProperty')} ${propertiesName}LowerThan(${property.type.toTypeName()} value, {bool include = false}) {
    return addWhereClause(WhereClause(
      $index,
      $propertyTypes,
      upper: [value],
      includeUpper: include
    ));
  }
  ''';
}

String generateGreaterThan(int index, String type, ObjectProperty property) {
  final propertiesName = joinPropertiesToName([property]);
  final propertyTypes = joinPropertiesToTypes([property]);
  return '''
  ${whereReturn(type, 'QWhereProperty')} ${propertiesName}GreaterThan(${property.type.toTypeName()} value, {bool include = false}) {
    return addWhereClause(WhereClause(
      $index,
      $propertyTypes,
      lower: [value],
      includeLower: include
    ));
  }
  ''';
}

String generateWhereBetween(int index, String type, ObjectProperty property) {
  final propertiesName = joinPropertiesToName([property]);
  final propertyTypes = joinPropertiesToTypes([property]);
  return '''
  ${whereReturn(type, 'QWhereProperty')} ${propertiesName}Between(${property.type.toTypeName()} lower, ${property.type.toTypeName()} upper, {bool includeLower = true, bool includeUpper = true}) {
    return addWhereClause(WhereClause(
      $index,
      $propertyTypes,
      upper: [upper],
      includeUpper: includeUpper,
      lower: [lower],
      includeLower: includeLower
    ));
  }
  ''';
}

String generateWhereAnyOf(String type, ObjectProperty property) {
  final propertiesName = joinPropertiesToName([property]);
  return '''
  ${whereReturn(type, 'QWhereProperty')} ${propertiesName}AnyOf(List<${property.type.toTypeName()}> values) {
    var q = this;
    for (var i = 0; i < values.length; i++) {
      if (i == values.length - 1) {
        return q.${propertiesName}EqualTo(values[i]);
      } else {
        q = q.${propertiesName}EqualTo(values[i]).or();
      }
    }
    throw UnimplementedError();
  }
  ''';
}

String generateWhereStartsWith(
    int index, String type, ObjectProperty property) {
  final propertiesName = joinPropertiesToName([property]);
  return '''
  ${whereReturn(type, 'QWhereProperty')} ${propertiesName}StartsWith(String prefix) {
    return addWhereCondition(QueryCondition(ConditionType.StartsWith, $index, [prefix]));
  }
  ''';
}
