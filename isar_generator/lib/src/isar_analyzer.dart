import 'dart:async';
import 'dart:convert';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:build/build.dart';
import 'package:isar_generator/src/helper.dart';
import 'package:isar_generator/src/object_info.dart';
import 'package:source_gen/source_gen.dart';
import 'package:isar_annotation/isar_annotation.dart' as isar;
import 'package:dartx/dartx.dart';

const OBJECT_ID_SIZE = 14;

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

    final modelClass = element as ClassElement;

    if (modelClass.isAbstract) {
      err('Object class must not be abstract.', element);
    }

    if (!modelClass.isPublic) {
      err('Object class must be public.', element);
    }

    final hasZeroArgConstructor = modelClass.constructors
        .any((c) => c.isPublic && !c.parameters.any((p) => !p.isOptional));

    if (!hasZeroArgConstructor) {
      err('Object class needs to have a public zero-arg constructor.');
    }

    final dbName = getNameAnn(modelClass)?.name ?? modelClass.displayName;
    if (dbName.isEmpty) {
      err('Empty model names are not allowed.', modelClass);
    }

    var properties = <ObjectProperty>[];
    final indices = <ObjectIndex>[];

    for (var property in modelClass.fields) {
      var modelProperty = generateObjectProperty(property);
      if (modelProperty == null) continue;
      properties.add(modelProperty);

      indices.addAll(generateObjectIndices(modelProperty, property));
    }

    properties = sortAndOffsetProperties(properties);

    final modelInfo = ObjectInfo(
      type: modelClass.displayName,
      dbName: dbName,
      properties: properties,
      indices: indices,
    );
    validateIndices(modelInfo);

    return modelInfo;
  }

  ObjectProperty generateObjectProperty(FieldElement property) {
    if (!property.isPublic ||
        property.isFinal ||
        property.isConst ||
        property.isStatic) {
      return null;
    }

    if (hasIgnoreAnn(property)) {
      return null;
    }

    var type = DataTypeX.fromTypeName(
      property.type.getDisplayString(withNullability: false),
    );
    if (type == null) {
      err('Property has unsupported type. Use @IsarIgnore to ignore the property.',
          property);
    }

    final nullable = property.type.nullabilitySuffix == NullabilitySuffix.none;
    final elementNullable = true;

    var dbName = getNameAnn(property)?.name ?? property.displayName;
    if (dbName.isEmpty) {
      err('Empty property names are not allowed.', property);
    }

    return ObjectProperty(
      name: property.displayName,
      dbName: dbName,
      type: type,
      nullable: nullable,
      elementNullable: elementNullable,
    );
  }

  Iterable<ObjectIndex> generateObjectIndices(
      ObjectProperty property, FieldElement element) {
    return getIndexAnns(element).map((index) {
      var properties = [property.name];
      properties.addAll(index.composite);

      var hashValue = index.hashValue;
      if (property.type == DataType.String && hashValue == null) {
        hashValue = false;
      }
      return ObjectIndex(
        properties: properties,
        unique: index.unique,
        hashValue: hashValue,
      );
    });
  }

  List<ObjectProperty> sortAndOffsetProperties(
      List<ObjectProperty> properties) {
    var offset = OBJECT_ID_SIZE;
    return properties
        .sortedBy((f) => f.type.index)
        .thenBy((f) => f.name)
        .mapIndexed((index, p) {
      final size = p.type.staticSize;
      final padding = -offset % size;
      offset += padding + size;
      return p.copyWith(staticPadding: padding);
    }).toList();
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
