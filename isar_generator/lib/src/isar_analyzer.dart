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
  final _annotationChecker = const TypeChecker.fromRuntime(isar.Collection);

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
      err('Only classes may be annotated with @IsarCollection.', element);
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

    for (var property in modelClass.properties) {
      var modelProperty = generateObjectProperty(property);
      if (modelProperty == null) continue;
      modelInfo.properties.add(modelProperty);

      modelInfo.indices.addAll(generateObjectIndices(modelProperty, property));
    }

    modelInfo.properties = modelInfo.properties
        .sortedBy((f) => f.type.index)
        .thenBy((f) => f.name);

    validateIndices(modelInfo);

    return modelInfo;
  }

  ObjectProperty generateObjectProperty(PropertyElement property) {
    if (!property.isPublic ||
        property.isFinal ||
        property.isConst ||
        property.isStatic) {
      return null;
    }

    if (hasIgnoreAnn(property)) {
      return null;
    }

    var type = DataTypeX.fromTypeName(property.type.toString());
    if (type == null) {
      err('Property has unsupported type. Use @IsarIgnore to ignore the property.',
          property);
    }

    var dbName = getNameAnn(property)?.name ?? property.displayName;
    if (dbName.isEmpty) {
      err('Empty property names are not allowed.', property);
    }

    return ObjectProperty(property.displayName, dbName, type, true);
  }

  Iterable<ObjectIndex> generateObjectIndices(
      ObjectProperty property, PropertyElement element) {
    return getIndexAnns(element).map((index) {
      var properties = [property.name];
      properties.addAll(index.composite);

      var hashValue = index.hashValue;
      if (property.type == DataType.String && hashValue == null) {
        hashValue = false;
      }
      return ObjectIndex(properties, index.unique, hashValue);
    });
  }

  void validateIndices(ObjectInfo model) {
    for (var index in model.indices) {
      for (var index2 in model.indices) {
        if (index == index2) continue;
        if (index.properties.length <= index2.properties.length) {
          if (index2.properties
              .take(index.properties.length)
              .contentEquals(index.properties)) {
            err('There are multiple indexes with the prefix "${index.properties.join(', ')}"');
          }
        }
      }

      for (var property in index.properties) {
        if (index.properties.count((e) => e == property) != 1) {
          err('There is a duplicate property in an index: "$property".');
        }
      }

      var hasStringProperty = index.properties
          .map((name) => model.properties.firstWhere((f) => f.name == name))
          .any((f) => f.type == DataType.String);

      if (index.hashValue != null) {
        if (index.properties.length > 1 && !index.hashValue) {
          err('String properties in composite indices need to be stored as hash.');
        }

        if (!hasStringProperty) {
          err('Only String and List<String> properties support the "hashValue" parameter.');
        }
      }
    }
  }

  @override
  final buildExtensions = {
    '.dart': ['.isarobject.json']
  };
}
