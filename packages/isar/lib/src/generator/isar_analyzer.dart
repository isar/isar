// ignore_for_file: use_string_buffers

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:isar/src/generator/consts.dart';
import 'package:isar/src/generator/helper.dart';
import 'package:isar/src/generator/isar_type.dart';
import 'package:isar/src/generator/object_info.dart';

class IsarAnalyzer {
  ObjectInfo analyzeCollection(Element element) {
    final constructor = _checkValidClass(element);
    final modelClass = element as ClassElement;

    final accessors = modelClass.allAccessors;
    final idProperties = accessors.where((e) => e.hasIdAnnotation).toList();
    final String idPropertyName;
    if (idProperties.isEmpty) {
      if (accessors.any((e) => e.name == 'id')) {
        idPropertyName = 'id';
      } else {
        err(
          'No id property defined. Annotate one of the properties with @id.',
          modelClass,
        );
      }
    } else if (idProperties.length == 1) {
      idPropertyName = idProperties.single.name;
    } else {
      err('Two or more properties are annotated with @id.', modelClass);
    }

    final properties = <PropertyInfo>[];
    var index = 1;
    for (final propertyElement in modelClass.allAccessors) {
      final isId = propertyElement.name == idPropertyName;
      final property = analyzePropertyInfo(
        propertyElement,
        constructor,
        isId && propertyElement.type.isDartCoreInt ? 0 : index,
        isId,
      );
      properties.add(property);
      if (!isId || property.type == PropertyType.string) {
        index++;
      }
    }
    _checkValidPropertiesConstructor(properties, constructor);

    return ObjectInfo(
      dartName: modelClass.name,
      isarName: modelClass.isarName,
      accessor: modelClass.collectionAccessor,
      properties: properties,
      embeddedDartNames: _getEmbeddedDartNames(element),
    );
  }

  ObjectInfo analyzeEmbedded(Element element) {
    final constructor = _checkValidClass(element);
    final modelClass = element as ClassElement;

    final properties = <PropertyInfo>[];
    for (var i = 0; i < modelClass.allAccessors.length; i++) {
      final propertyElement = modelClass.allAccessors[i];
      final property =
          analyzePropertyInfo(propertyElement, constructor, i + 1, false);
      properties.add(property);
    }
    _checkValidPropertiesConstructor(properties, constructor);

    /*final hasIndex = modelClass.allAccessors.any(
      (it) => it.indexAnnotations.isNotEmpty,
    );
    if (hasIndex) {
      err('Embedded objects must not have indexes.', modelClass);
    }*/

    return ObjectInfo(
      dartName: modelClass.name,
      isarName: modelClass.isarName,
      properties: properties,
    );
  }

  ConstructorElement _checkValidClass(Element modelClass) {
    if (modelClass is! ClassElement ||
        modelClass is EnumElement ||
        modelClass is MixinElement) {
      err(
        'Only classes may be annotated with @Collection or @Embedded.',
        modelClass,
      );
    }

    if (modelClass.isAbstract) {
      err('Class must not be abstract.', modelClass);
    }

    if (!modelClass.isPublic) {
      err('Class must be public.', modelClass);
    }

    final constructor = modelClass.constructors
        .where((c) => c.periodOffset == null)
        .firstOrNull;
    if (constructor == null) {
      err('Class needs an unnamed constructor.', modelClass);
    }

    final hasCollectionSupertype = modelClass.allSupertypes.any((type) {
      return type.element.collectionAnnotation != null ||
          type.element.embeddedAnnotation != null;
    });
    if (hasCollectionSupertype) {
      err(
        'Class must not have a supertype annotated with @Collection or '
        '@Embedded.',
        modelClass,
      );
    }

    return constructor;
  }

  void _checkValidPropertiesConstructor(
    List<PropertyInfo> properties,
    ConstructorElement constructor,
  ) {
    if (properties.map((e) => e.isarName).toSet().length != properties.length) {
      err(
        'Two or more properties have the same name.',
        constructor.enclosingElement,
      );
    }

    final unknownConstructorParameter = constructor.parameters
        .where(
          (p) => p.isRequired && !properties.any((e) => e.dartName == p.name),
        )
        .firstOrNull;
    if (unknownConstructorParameter != null) {
      err(
        'Constructor parameter does not match a property.',
        unknownConstructorParameter,
      );
    }
  }

  Set<String> _getEmbeddedDartNames(ClassElement element) {
    void fillNames(Set<String> names, ClassElement element) {
      for (final property in element.allAccessors) {
        final type = property.type.scalarType.element;
        if (type is ClassElement && type.embeddedAnnotation != null) {
          if (names.add(type.name)) {
            fillNames(names, type);
          }
        }
      }
    }

    final names = <String>{};
    fillNames(names, element);
    return names;
  }

  PropertyInfo analyzePropertyInfo(
    PropertyInducingElement property,
    ConstructorElement constructor,
    int propertyIndex,
    bool isId,
  ) {
    final dartType = property.type;
    Map<String, dynamic>? enumMap;
    String? enumPropertyName;

    late final PropertyType type;
    if (dartType.scalarType.element is EnumElement) {
      final enumClass = dartType.scalarType.element! as EnumElement;
      final enumElements =
          enumClass.fields.where((f) => f.isEnumConstant).toList();

      final enumProperty = enumClass.enumValueProperty;
      enumPropertyName = enumProperty?.name ?? 'index';
      if (enumProperty != null &&
          enumProperty.nonSynthetic is PropertyAccessorElement) {
        err('Only fields are supported for enum properties', enumProperty);
      }

      final enumPropertyType = enumProperty == null
          ? PropertyType.byte
          : enumProperty.type.propertyType;
      if (enumPropertyType != PropertyType.byte &&
          enumPropertyType != PropertyType.int &&
          enumPropertyType != PropertyType.long &&
          enumPropertyType != PropertyType.string) {
        err('Unsupported enum property type.', enumProperty);
      }

      type = dartType.isDartCoreList
          ? enumPropertyType!.listType
          : enumPropertyType!;
      enumMap = {};
      for (var i = 0; i < enumElements.length; i++) {
        final element = enumElements[i];
        dynamic propertyValue = i;
        if (enumProperty != null) {
          final property =
              element.computeConstantValue()!.getField(enumProperty.name)!;
          propertyValue = property.toBoolValue() ??
              property.toIntValue() ??
              property.toDoubleValue() ??
              property.toStringValue();
        }

        if (propertyValue == null) {
          err(
            'Null values are not supported for enum properties.',
            enumProperty,
          );
        }

        if (enumMap.values.contains(propertyValue)) {
          err(
            'Enum property has duplicate values.',
            enumProperty,
          );
        }
        enumMap[element.name] = propertyValue;
      }
    } else {
      if (dartType.propertyType != null) {
        type = dartType.propertyType!;
      } else if (dartType.supportsJsonConversion) {
        type = PropertyType.json;
      } else {
        err(
          'Unsupported type. Please add @embedded to the type or implement '
          'toJson() and fromJson() methods or annotate the property with '
          '@ignore let Isar to ignore it.',
          property,
        );
      }
    }

    final nullable = dartType.nullabilitySuffix != NullabilitySuffix.none;
    if (isId) {
      if (type != PropertyType.long && type != PropertyType.string) {
        err('Only int and String properties can be used as id.', property);
      } else if (nullable) {
        err('Id properties must not be nullable.', property);
      }
    }

    final constructorParameter = constructor.parameters
        .where((p) => p.name == property.name)
        .firstOrNull;
    int? constructorPosition;
    late DeserializeMode mode;
    if (constructorParameter != null) {
      if (constructorParameter.type != property.type) {
        err(
          'Constructor parameter type does not match property type',
          constructorParameter,
        );
      }
      mode = constructorParameter.isNamed
          ? DeserializeMode.namedParam
          : DeserializeMode.positionalParam;
      constructorPosition =
          constructor.parameters.indexOf(constructorParameter);
    } else {
      mode = property.setter == null
          ? DeserializeMode.none
          : DeserializeMode.assign;
    }

    return PropertyInfo(
      index: propertyIndex,
      dartName: property.name,
      isarName: property.isarName,
      typeClassName: type == PropertyType.json
          ? dartType.element!.name!
          : dartType.scalarType.element!.name!,
      targetIsarName:
          type.isObject ? dartType.scalarType.element!.isarName : null,
      type: type,
      isId: isId,
      enumMap: enumMap,
      enumProperty: enumPropertyName,
      nullable: nullable,
      elementNullable: type.isList
          ? dartType.scalarType.nullabilitySuffix != NullabilitySuffix.none
          : null,
      defaultValue:
          constructorParameter?.defaultValueCode ?? _defaultValue(dartType),
      elementDefaultValue:
          type.isList ? _defaultValue(dartType.scalarType) : null,
      utc: type.isDate && property.hasUtcAnnotation,
      mode: mode,
      assignable: property.setter != null,
      constructorPosition: constructorPosition,
    );
  }

  String _defaultValue(DartType type) {
    if (type.nullabilitySuffix == NullabilitySuffix.question ||
        type is DynamicType) {
      return 'null';
    } else if (type.isDartCoreInt) {
      if (type.propertyType == PropertyType.byte) {
        return '$nullByte';
      } else if (type.propertyType == PropertyType.int) {
        return '$nullInt';
      } else {
        return '$nullLong';
      }
    } else if (type.isDartCoreDouble) {
      return 'double.nan';
    } else if (type.isDartCoreBool) {
      return 'false';
    } else if (type.isDartCoreString) {
      return "''";
    } else if (type.isDartCoreDateTime) {
      return 'DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).toLocal()';
    } else if (type.isDartCoreList) {
      return 'const <${type.scalarType}>[]';
    } else if (type.isDartCoreMap) {
      return 'const <String, dynamic>{}';
    } else {
      final element = type.element!;
      if (element is EnumElement) {
        return '${element.name}.${element.fields.where((f) => f.isEnumConstant).first.name}';
      } else if (element is ClassElement) {
        final defaultConstructor = _checkValidClass(element);
        var code = '${element.name}(';
        for (final param in defaultConstructor.parameters) {
          if (!param.isOptional) {
            if (param.isNamed) {
              code += '${param.name}: ';
            }
            code += _defaultValue(param.type);
            code += ', ';
          }
        }
        return '$code)';
      }
    }

    throw UnimplementedError('This should not happen');
  }
}
