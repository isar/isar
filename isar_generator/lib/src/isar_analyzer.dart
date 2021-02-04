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

const primaryKeyTypes = [IsarType.String, IsarType.Int, IsarType.Long];

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

    final hasZeroArgConstructor = modelClass.constructors
        .any((c) => c.isPublic && !c.parameters.any((p) => !p.isOptional));

    if (!hasZeroArgConstructor) {
      err('Object class needs to have a public zero-arg constructor.');
    }

    final isarName = getNameAnn(modelClass)?.name ?? modelClass.displayName;
    if (isarName.isEmpty) {
      err('Empty model names are not allowed.', modelClass);
    }

    ObjectProperty oidProperty;
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

      final hasOidAnn = hasObjectIdAnn(property);
      if (hasOidAnn) {
        if (converter != null) {
          err('Converters are not allowed for ids.', property);
        } else if (!primaryKeyTypes.contains(modelProperty.isarType)) {
          err('Illegal ObjectId type. Allowed: String, Int, Long', property);
        } else if (oidProperty != null) {
          err('More than one properties are annotated with @ObjectId().',
              element);
        }
        oidProperty = modelProperty;
      } else {
        properties.add(modelProperty);
        final index = generateObjectIndices(modelProperty, property);
        if (index != null) {
          indices.add(index);
        }
      }
    }

    if (oidProperty == null) {
      for (var i = 0; i < properties.length; i++) {
        final property = properties[i];
        if (property.isarName == 'id' &&
            property.converter == null &&
            primaryKeyTypes.contains(property.isarType)) {
          oidProperty = properties[i];
          properties.removeAt(i);
          break;
        }
      }
      if (oidProperty == null) {
        err('No property annotated with @ObjectId().', element);
      }
    }

    final modelInfo = ObjectInfo(
      dartName: modelClass.displayName,
      isarName: isarName,
      oidProperty: oidProperty,
      properties: properties,
      indices: indices,
      converterImports: converterImports.toList(),
    );
    validateIndices(element, modelInfo);

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

    var type = property.type.getDisplayString(withNullability: true);
    if (type.endsWith('*')) {
      type = type.removeSuffix('*') + '?';
    }
    return ObjectProperty(
      dartName: property.displayName,
      isarName: isarName,
      dartType: type,
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

  ObjectIndex generateObjectIndices(
      ObjectProperty property, FieldElement element) {
    final indexAnns = getIndexAnns(element).toList();
    if (indexAnns.isEmpty) {
      return null;
    } else if (indexAnns.length > 1) {
      err('Property must not have more than one @Index annotations.', element);
    }

    final index = indexAnns[0];
    final indexProperties = <ObjectIndexProperty>[];

    indexProperties.add(ObjectIndexProperty(
      isarName: property.isarName,
      stringType: index.stringType,
      caseSensitive: index.caseSensitive ?? true,
    ));
    for (var c in index.composite) {
      indexProperties.add(ObjectIndexProperty(
        isarName: c.property,
        stringType: c.stringType,
        caseSensitive: c.caseSensitive ?? true,
      ));
    }
    return ObjectIndex(
      properties: indexProperties,
      unique: index.unique,
    );
  }

  void validateIndices(Element element, ObjectInfo model) {
    for (var index in model.indices) {
      for (var index2 in model.indices) {
        if (index == index2) continue;
        if (index.properties.length <= index2.properties.length) {
          final indexProperties = index.properties.map((it) => it.isarName);
          final index2Properties = index2.properties
              .take(index.properties.length)
              .map((it) => it.isarName);
          if (indexProperties.contentEquals(index2Properties)) {
            err('There are multiple indexes with the prefix "${indexProperties.join(', ')}"',
                element);
          }
        }
      }

      if (index.properties.map((it) => it.isarName).distinct().length !=
          index.properties.length) {
        err('Composite index contains duplicate properties.', element);
      }

      for (var i = 0; i < index.properties.length; i++) {
        final indexProperty = index.properties[i];
        final property = model.properties
            .firstOrNullWhere((it) => it.isarName == indexProperty.isarName);
        if (property == null) {
          err('Property does not exist: "${indexProperty.isarName}".', element);
        }
        if (property.isarType == IsarType.String) {
          if (indexProperty.stringType == isar.StringIndexType.value &&
              i != index.properties.lastIndex) {
            err('Only the last property of a composite index may use StringIndexType.value.',
                element);
          } else if (indexProperty.stringType == isar.StringIndexType.words &&
              index.properties.length != 1) {
            err('StringIndexType.words is not allowed for composite indexes.',
                element);
          }
        } else if (indexProperty.stringType != null) {
          err('Only String indices may have a StringIndexType.', element);
        }
      }
    }
  }

  @override
  final buildExtensions = {
    '.dart': ['.isarobject.json']
  };
}
