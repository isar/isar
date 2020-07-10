import 'package:isar/internal.dart';
import 'package:isar_generator/src/code_gen/util.dart';
import 'package:isar_generator/src/object_info.dart';
import 'package:dartx/dartx.dart';

String generateQueryWhere(ObjectInfo object) {
  var code = '''
  extension ${object.type}QueryWhere on QueryBuilder<${object.type}, 
    IsarBank<${object.type}>, NoWhere, dynamic, dynamic, dynamic> {
  ''';
  for (var index in object.indices) {
    for (var i = 0; i < index.fields.length; i++) {
      var fields = index.fields
          .sublist(0, i + 1)
          .map((f) => object.getField(f))
          .toList();

      if (fields.all((it) => it.type != DataType.Double)) {
        var whereEqualToBody = generateWhereEqualToNative(
            object.type, fields, object.indices.indexOf(index));
        code += generateWhereEqualTo(object.type, fields, whereEqualToBody);
        code += generateWhereNotEqualTo(object.type, fields);
      }
      code += generateWhereBetween(object.type, fields);

      if (fields.length == 1) {
        var field = fields.first;
        if (field.type != DataType.Double) {
          code += generateWhereAnyOf(object.type, field);
        }

        if (field.type == DataType.String) {
          code += generateWhereBeginsWith(object.type, field);
        }
      }
    }
  }
  return '''
    $code
  }''';
}

String joinFieldsToName(List<ObjectField> fields) {
  return fields
      .mapIndexed(
          (i, f) => i == 0 ? f.name.decapitalize() : f.name.capitalize())
      .join('');
}

String joinFieldsToParams(List<ObjectField> fields) {
  return fields.map((it) => '${it.type.toTypeName()} ${it.name}').join(',');
}

String wcAdd(String name, DataType type, bool lower) {
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
}

String generateWhereEqualTo(
    String type, List<ObjectField> fields, String body) {
  return '''
  QueryBuilder<$type, IsarBank<$type>, WhereField, CanFilter, CanSort, CanExecute> 
    ${joinFieldsToName(fields)}EqualTo(${joinFieldsToParams(fields)}) {
    $body
  }
  ''';
}

String generateWhereEqualToNative(
    String type, List<ObjectField> fields, int index) {
  var size = fields.sumBy((f) => f.type.staticSize()).toInt();
  var addProperties = fields
      .map((f) => wcAdd(f.name, f.type, true) + wcAdd(f.name, f.type, false))
      .join('\n');
  return '''
  var wc = isarBindings.createWc(${getBankVar(type)}, $size, $size);
  var qb = this as QueryBuilderImpl;
  $addProperties
  return QueryBuilder();
  ''';
}

String generateWhereNotEqualTo(String type, List<ObjectField> fields) {
  return '''
  QueryBuilder<$type, IsarBank<$type>, WhereField, CanFilter, CanSort, CanExecute> 
    ${joinFieldsToName(fields)}NotEqualTo(${joinFieldsToParams(fields)}) {
    return QueryBuilder();
  }
  ''';
}

String generateWhereBetween(String type, List<ObjectField> fields) {
  var paramsStart =
      fields.map((it) => '${it.type.toTypeName()} ${it.name}Start').join(',');
  var paramsEnd =
      fields.map((it) => '${it.type.toTypeName()} ${it.name}End').join(',');
  return '''
  QueryBuilder<$type, IsarBank<$type>, WhereField, CanFilter, CanSort, CanExecute> 
    ${joinFieldsToName(fields)}Between({$paramsStart, $paramsEnd}) {
    return QueryBuilder();
  }
  ''';
}

String generateWhereAnyOf(String type, ObjectField field) {
  var fieldsName = joinFieldsToName([field]);
  return '''
  QueryBuilder<$type, IsarBank<$type>, WhereField, CanFilter, CanSort, CanExecute> 
    ${fieldsName}AnyOf(List<${field.type.toTypeName()}> values) {
    var q = this;
    for (var i = 0; i < values.length; i++) {
      if (i == values.length - 1) {
        return q.${fieldsName}EqualTo(values[i]);
      } else {
        q = q.${fieldsName}EqualTo(values[i]).or();
      }
    }
    throw UnimplementedError();
  }
  ''';
}

String generateWhereBeginsWith(String type, ObjectField field) {
  var fieldsName = joinFieldsToName([field]);
  return '''
  QueryBuilder<$type, IsarBank<$type>, WhereField, CanFilter, CanSort, CanExecute> 
    ${fieldsName}BeginsWith(String prefix) {
    return QueryBuilder();
  }
  ''';
}
