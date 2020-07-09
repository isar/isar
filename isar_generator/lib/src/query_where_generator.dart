import 'package:isar_generator/src/object_info.dart';
import 'package:dartx/dartx.dart';

String generateQueryWhere(ObjectInfo object) {
  var code = """
  extension ${object.name}QueryWhere on QueryBuilder<${object.name}, 
    IsarBank<${object.name}>, NoWhere, dynamic, dynamic, dynamic> {
  """;
  for (var index in object.indices) {
    for (var i = 0; i < index.fields.length; i++) {
      var fields = index.fields
          .sublist(0, i + 1)
          .map((f) => object.getField(f))
          .toList();

      if (fields.all((it) => it.type != DataType.Double)) {
        code += generateWhereEqualTo(object.name, fields) + "\n";
        code += generateWhereNotEqualTo(object.name, fields) + "\n";
      }
      code += generateWhereBetween(object.name, fields) + "\n";

      if (fields.length == 1) {
        var field = fields.first;
        if (field.type != DataType.Double) {
          code += generateWhereAnyOf(object.name, field) + "\n";
        }

        if (field.type == DataType.String) {
          code += generateWhereBeginsWith(object.name, field) + "\n";
        }
      }
    }
  }
  return """
    $code
  }""";
}

String joinFieldsToName(List<ObjectField> fields) {
  return fields
      .mapIndexed(
          (i, f) => i == 0 ? f.name.decapitalize() : f.name.capitalize())
      .join("");
}

String joinFieldsToParams(List<ObjectField> fields) {
  return fields.map((it) => "${it.type.toTypeName()} ${it.name}").join(",");
}

String generateWhereEqualTo(String type, List<ObjectField> fields) {
  return """
  QueryBuilder<$type, IsarBank<$type>, WhereField, CanFilter, CanSort, CanExecute> 
    ${joinFieldsToName(fields)}EqualTo(${joinFieldsToParams(fields)}) {
    return QueryBuilder();
  }
  """;
}

String generateWhereNotEqualTo(String type, List<ObjectField> fields) {
  return """
  QueryBuilder<$type, IsarBank<$type>, WhereField, CanFilter, CanSort, CanExecute> 
    ${joinFieldsToName(fields)}NotEqualTo(${joinFieldsToParams(fields)}) {
    return QueryBuilder();
  }
  """;
}

String generateWhereBetween(String type, List<ObjectField> fields) {
  var paramsStart =
      fields.map((it) => "${it.type.toTypeName()} ${it.name}Start").join(",");
  var paramsEnd =
      fields.map((it) => "${it.type.toTypeName()} ${it.name}End").join(",");
  return """
  QueryBuilder<$type, IsarBank<$type>, WhereField, CanFilter, CanSort, CanExecute> 
    ${joinFieldsToName(fields)}Between({$paramsStart, $paramsEnd}) {
    return QueryBuilder();
  }
  """;
}

String generateWhereAnyOf(String type, ObjectField field) {
  var fieldsName = joinFieldsToName([field]);
  return """
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
  """;
}

String generateWhereBeginsWith(String type, ObjectField field) {
  var fieldsName = joinFieldsToName([field]);
  return """
  QueryBuilder<$type, IsarBank<$type>, WhereField, CanFilter, CanSort, CanExecute> 
    ${fieldsName}BeginsWith(String prefix) {
    return QueryBuilder();
  }
  """;
}
