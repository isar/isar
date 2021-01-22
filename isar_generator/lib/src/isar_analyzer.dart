import 'dart:async';
import 'dart:convert';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
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
    print(json);
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

    final isIsarObject = modelClass.allSupertypes
        .any((element) => element.element.name == 'IsarObject');
    if (!isIsarObject) {
      err('Object class has to extend or mixin IsarObject.', element);
    }

    final hasZeroArgConstructor = modelClass.constructors
        .any((c) => c.isPublic && !c.parameters.any((p) => !p.isOptional));

    if (!hasZeroArgConstructor) {
      err('Object class needs to have a public zero-arg constructor.');
    }

    final isarName = getNameAnn(modelClass)?.name ?? modelClass.displayName;
    if (isarName.isEmpty) {
      err('Empty model names are not allowed.', modelClass);
    }

    var properties = <ObjectProperty>[];
    final indices = <ObjectIndex>[];
    final converterImports = <String>{};

    for (var property in modelClass.fields) {
      final converter = findTypeConverter(property);
      if (converter != null) {
        final pathComponents = converter.location.components[0].split('/');
        converterImports.add(pathComponents.sublist(2).join('/'));
      }

      var modelProperty = generateObjectProperty(property, converter);
      if (modelProperty == null) continue;
      properties.add(modelProperty);

      indices.addAll(generateObjectIndices(modelProperty, property));
    }

    properties = sortAndOffsetProperties(properties);

    final modelInfo = ObjectInfo(
      dartName: modelClass.displayName,
      isarName: isarName,
      properties: properties,
      indices: indices,
      converterImports: converterImports.toList(),
    );
    validateIndices(modelInfo);

    return modelInfo;
  }

  ClassElement findTypeConverter(FieldElement property) {
    final annotations = getTypeConverterAnns(property);
    annotations.addAll(getTypeConverterAnns(property.enclosingElement));

    for (var annotation in annotations) {
      final cls = annotation.type.element as ClassElement;
      final dartType = cls.supertype.typeArguments[0];
      if (dartType == property.type) {
        return cls;
      }
    }

    return null;
  }

  ObjectProperty generateObjectProperty(
      FieldElement property, ClassElement converter) {
    if (!property.isPublic ||
        property.isFinal ||
        property.isConst ||
        property.isStatic) {
      return null;
    }

    if (hasIgnoreAnn(property)) {
      return null;
    }

    final nullable = property.type.nullabilitySuffix != NullabilitySuffix.none;
    var elementNullable = false;
    if (property.type is ParameterizedType) {
      final typeArguments = (property.type as ParameterizedType).typeArguments;
      if (typeArguments != null && typeArguments.isNotEmpty) {
        final listType = typeArguments[0];
        elementNullable = listType.nullabilitySuffix != NullabilitySuffix.none;
      }
    }

    final nameAnn = getNameAnn(property);
    if (nameAnn != null && nameAnn.name.isEmpty) {
      err('Empty property names are not allowed.', property);
    }
    var isarName = nameAnn?.name ?? property.displayName;

    IsarType isarType;
    if (converter == null) {
      final size32 = hasSize32Ann(property);
      isarType = getIsarType(property.type, size32, property);
    } else {
      final isarDartType = converter.supertype.typeArguments[1];
      final size32 = hasSize32Ann(converter);
      isarType = getIsarType(isarDartType, size32, converter);
    }

    return ObjectProperty(
      dartName: property.displayName,
      isarName: isarName,
      dartType: property.type.getDisplayString(withNullability: true),
      isarType: isarType,
      converter: converter?.name,
      nullable: nullable,
      elementNullable: elementNullable,
    );
  }

  IsarType getIsarType(DartType type, bool size32, Element element) {
    if (type.isDartCoreBool) {
      return IsarType.Bool;
    } else if (type.isDartCoreInt) {
      if (size32) {
        return IsarType.Int;
      } else {
        return IsarType.Long;
      }
    } else if (type.isDartCoreDouble) {
      if (size32) {
        return IsarType.Float;
      } else {
        return IsarType.Double;
      }
    } else if (type.isDartCoreString) {
      return IsarType.String;
    } else if (type.isDartCoreList) {
      final parameterizedType = type as ParameterizedType;
      final typeArguments = parameterizedType.typeArguments;
      if (typeArguments != null && typeArguments.isNotEmpty) {
        final listType = typeArguments[0];
        if (listType.isDartCoreBool) {
          return IsarType.BoolList;
        } else if (listType.isDartCoreInt) {
          if (size32) {
            return IsarType.IntList;
          } else {
            return IsarType.LongList;
          }
        } else if (listType.isDartCoreDouble) {
          if (size32) {
            return IsarType.FloatList;
          } else {
            return IsarType.DoubleList;
          }
        } else if (listType.isDartCoreString) {
          return IsarType.StringList;
        }
      }
    } else if (type.element.name == 'Uint8List') {
      return IsarType.Bytes;
    }
    err('Property has unsupported type. Use @IsarIgnore to ignore the property.',
        element);
    throw 'unreachable';
  }

  Iterable<ObjectIndex> generateObjectIndices(
      ObjectProperty property, FieldElement element) {
    return getIndexAnns(element).map((index) {
      var properties = [property.isarName];
      properties.addAll(index.composite);

      var hashValue = index.hashValue;
      if (property.isarType == IsarType.String && hashValue == null) {
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
        .sortedBy((f) => f.isarType.typeId)
        .thenBy((f) => f.isarName)
        .mapIndexed((index, p) {
      final size = p.isarType.staticSize;
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
          .map((name) => model.properties.firstWhere((f) => f.isarName == name))
          .any((f) => f.isarType == IsarType.String);

      if (index.hashValue && !hasStringProperty) {
        err('Only String and List<String> properties support the "hashValue" parameter.');
      }
      if (index.properties.length > 1 && !index.hashValue) {
        err('String properties in composite indices need to be stored as hash.');
      }
    }
  }

  @override
  final buildExtensions = {
    '.dart': ['.isarobject.json']
  };
}
