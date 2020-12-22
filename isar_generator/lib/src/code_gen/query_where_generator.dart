import 'package:isar_generator/src/object_info.dart';
import 'package:dartx/dartx.dart';

String generateQueryWhere(ObjectInfo object) {
  var whereSort = object.indices.mapIndexed((i, index) {
    var properties =
        index.properties.map((f) => object.getProperty(f)).toList();
    return generateSortedBy(i, object.type, properties);
  }).join('\n');

  var where = object.indices.mapIndexed((i, index) {
    var code = '';
    for (var n = 0; n < index.properties.length; n++) {
      var properties = index.properties
          .sublist(0, n + 1)
          .map((f) => object.getProperty(f))
          .toList();

      if (properties.all((it) => it.type != DataType.Double)) {
        code += generateWhereEqualTo(i, object.type, properties);
        code += generateWhereNotEqualTo(i, object.type, properties);
      }
      code += generateWhereBetween(i, object.type, properties);

      if (properties.length == 1) {
        var property = properties.first;
        if (property.type != DataType.Double) {
          code += generateWhereAnyOf(object.type, property);
        }

        if (property.type == DataType.String) {
          code += generateWhereBeginsWith(i, object.type, property);
        }
      }
    }
    return code;
  }).join('\n');

  return '''
  extension ${object.type}QueryWhereSort on Query<${object.type}, 
    IsarCollection<${object.type}>, QNoWhere, dynamic, dynamic, dynamic, dynamic> {
    $whereSort
  }
  
  extension ${object.type}QueryWhere on Query<${object.type}, 
    IsarCollection<${object.type}>, QWhere, dynamic, dynamic, dynamic, dynamic> {
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
    [String suffix = '']) {
  return properties
      .map((it) => '${it.type.toTypeName()} ${it.name}$suffix')
      .join(',');
}

String joinPropertiesToList(List<ObjectProperty> properties,
    [String suffix = '']) {
  return '[' + properties.map((it) => it.name + suffix).join(', ') + ']';
}

/*String wcAdd(String name, DataType type, bool lower) {
  if (type == DataType.Int) {
    return 'isarBindings.wcAddInt(wc, ${nBool(lower)}, $name);';
  } else if (type == DataType.Double) {
    return 'isarBindings.wcAddDouble(wc, ${nBool(lower)}, $name);';
  } else if (type == DataType.Bool) {
    return 'isarBindings.wcAddBool(wc, ${nBool(lower)}, $name ? 1 : 0);';
  } else {
    return '''
    var ${name}Ptr = Utf8.toUtf8($name);
    isarBindings.wcAddString(wc, ${nBool(lower)}, ${name}Ptr);
    free(${name}Ptr);
    ''';
  }
}*/

String generateSortedBy(
    int index, String type, List<ObjectProperty> properties) {
  return '''
  Query<$type, IsarCollection<$type>, dynamic, QCanFilter, QNoGroups, QCanSort, QCanExecute> 
    sortedBy${joinPropertiesToName(properties).capitalize()}() {
    return copy();
  }
  ''';
}

String generateWhereEqualTo(
    int index, String type, List<ObjectProperty> properties) {
  return '''
  Query<$type, IsarCollection<$type>, QWhereProperty, QCanFilter, QNoGroups, QCanSort, QCanExecute> 
    ${joinPropertiesToName(properties)}EqualTo(${joinPropertiesToParams(properties)}) {
    addWhereCondition(QueryCondition(ConditionType.Eq, $index, [${joinPropertiesToList(properties)}]));
    return copy();
  }
  ''';
}

/*String generateWhereEqualToNative(
    String type, List<ObjectProperty> properties, int index) {
  var size = properties.sumBy((f) => f.type.staticSize()).toInt();
  var addProperties = properties
      .map((f) => wcAdd(f.name, f.type, true) + wcAdd(f.name, f.type, false))
      .join('\n');
  return '''
  var wc = isarBindings.createWc(${getCollectionVar(type)}, $size, $size);
  var qb = this as QueryBuilderImpl;
  $addProperties
  return copy();
  ''';
}*/

String generateWhereNotEqualTo(
    int index, String type, List<ObjectProperty> properties) {
  return '''
  Query<$type, IsarCollection<$type>, QWhereProperty, QCanFilter, QNoGroups, QCanSort, QCanExecute> 
    ${joinPropertiesToName(properties)}NotEqualTo(${joinPropertiesToParams(properties)}) {
    addWhereCondition(QueryCondition(ConditionType.NEq, $index, [${joinPropertiesToList(properties)}]));
    return copy();
  }
  ''';
}

String generateWhereBetween(
    int index, String type, List<ObjectProperty> properties) {
  return '''
  Query<$type, IsarCollection<$type>, QWhereProperty, QCanFilter, QNoGroups, QCanSort, QCanExecute> 
    ${joinPropertiesToName(properties)}Between({${joinPropertiesToParams(properties, 'Start')}, ${joinPropertiesToParams(properties, 'End')}}) {
    addWhereCondition(QueryBetween($index, ${joinPropertiesToList(properties, 'Start')}, ${joinPropertiesToList(properties, 'End')}));
    return copy();
  }
  ''';
}

String generateWhereAnyOf(String type, ObjectProperty property) {
  var propertiesName = joinPropertiesToName([property]);
  return '''
  Query<$type, IsarCollection<$type>, QWhereProperty, QCanFilter, QNoGroups, QCanSort, QCanExecute> 
    ${propertiesName}AnyOf(List<${property.type.toTypeName()}> values) {
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

String generateWhereBeginsWith(
    int index, String type, ObjectProperty property) {
  var propertiesName = joinPropertiesToName([property]);
  return '''
  Query<$type, IsarCollection<$type>, QWhereProperty, QCanFilter, QCanSort, QCanExecute> 
    ${propertiesName}BeginsWith(String prefix) {
    addWhereCondition(QueryCondition(ConditionType.BeginsWith, $index, [prefix]));
    return QueryBuilder();
  }
  ''';
}
