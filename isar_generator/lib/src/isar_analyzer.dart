import 'dart:async';
import 'dart:convert';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:isar_generator/src/helper.dart';
import 'package:isar_generator/src/object_info.dart';
import 'package:source_gen/source_gen.dart';
import 'package:isar/isar.dart' as isar;
import 'package:dartx/dartx.dart';

class IsarAnalyzer extends Builder {
  final _annotationChecker = const TypeChecker.fromRuntime(isar.Bank);

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final resolver = buildStep.resolver;
    if (!await resolver.isLibrary(buildStep.inputId)) return;
    final libReader = LibraryReader(await buildStep.inputLibrary);

    var models = libReader
        .annotatedWith(_annotationChecker)
        .map((e) => generateObjectInfo(e.element).toJson())
        .toList();

    if (models.isEmpty) return;

    var json = JsonEncoder().convert(models);
    await buildStep.writeAsString(
        buildStep.inputId.changeExtension('.isarobject.json'), json);
  }

  ObjectInfo generateObjectInfo(Element element) {
    if (element is! ClassElement) {
      err('Only classes may be annotated with @IsarBank.', element);
    }

    var modelClass = element as ClassElement;

    if (modelClass.isAbstract) {
      err('Object class must not be abstract.', element);
    }

    if (!modelClass.isPublic) {
      err('Object class must be public.', element);
    }

    var hasZeroArgConstructor = modelClass.constructors
        .any((c) => c.isPublic && !c.parameters.any((p) => !p.isOptional));

    if (!hasZeroArgConstructor) {
      err('Object class needs to have a public zero-arg constructor.');
    }

    var dbName = getNameAnn(modelClass)?.name ?? modelClass.displayName;
    if (dbName.isEmpty) {
      err('Empty model names are not allowed.', modelClass);
    }

    var modelInfo = ObjectInfo(modelClass.displayName, dbName);

    for (var field in modelClass.fields) {
      var modelField = generateObjectField(field);
      if (modelField == null) continue;
      modelInfo.fields.add(modelField);

      modelInfo.indices.addAll(generateObjectIndices(modelField, field));
    }

    modelInfo.fields =
        modelInfo.fields.sortedBy((f) => f.type.index).thenBy((f) => f.name);

    validateIndices(modelInfo);

    return modelInfo;
  }

  ObjectField generateObjectField(FieldElement field) {
    if (!field.isPublic || field.isFinal || field.isConst || field.isStatic) {
      return null;
    }

    if (hasIgnoreAnn(field)) {
      return null;
    }

    var type = DataTypeX.fromTypeName(field.type.toString());
    if (type == null) {
      err('Field has unsupported type. Use @IsarIgnore to ignore the field.',
          field);
    }

    var dbName = getNameAnn(field)?.name ?? field.displayName;
    if (dbName.isEmpty) {
      err('Empty field names are not allowed.', field);
    }

    return ObjectField(field.displayName, dbName, type, true);
  }

  Iterable<ObjectIndex> generateObjectIndices(
      ObjectField field, FieldElement element) {
    return getIndexAnns(element).map((index) {
      var fields = [field.name];
      fields.addAll(index.composite);

      var hashValue = index.hashValue;
      if (field.type == DataType.String && hashValue == null) {
        hashValue = false;
      }
      return ObjectIndex(fields, index.unique, hashValue);
    });
  }

  void validateIndices(ObjectInfo model) {
    for (var index in model.indices) {
      for (var index2 in model.indices) {
        if (index == index2) continue;
        if (index.fields == index2.fields) {
          err('There is a duplicate index for the fields "${index.fields.join(', ')}"');
        }
      }

      var hasStringField = index.fields
          .map((name) => model.fields.firstWhere((f) => f.name == name))
          .any((f) => f.type == DataType.String);

      if (index.hashValue != null) {
        if (index.fields.length > 1 && !index.hashValue) {
          err('String fields in composite indices need to be stored as hash.');
        }

        if (!hasStringField) {
          err('Only String and List<String> fields support the "hashValue" parameter.');
        }
      }
    }
  }

  @override
  final buildExtensions = {
    '.dart': ['.isarobject.json']
  };
}
