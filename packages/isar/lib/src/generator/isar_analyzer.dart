import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:isar/isar.dart';
import 'package:isar/src/generator/consts.dart';
import 'package:isar/src/generator/helper.dart';
import 'package:isar/src/generator/isar_type.dart';
import 'package:isar/src/generator/object_info.dart';

class IsarAnalyzer {
  ObjectInfo analyzeCollection(Element element) {
    final constructor = _checkValidClass(element);
    final modelClass = element as ClassElement;

    final properties = <PropertyInfo>[];
    for (final propertyElement in modelClass.allAccessors) {
      final property = analyzePropertyInfo(propertyElement, constructor);
      properties.add(property);
    }
    _checkValidPropertiesConstructor(properties, constructor);

    final idProperties = properties.where((it) => it.isId);
    if (idProperties.isEmpty) {
      err(
        'No id property defined. Annotate one of the properties with @id.',
        modelClass,
      );
    } else if (idProperties.length > 1) {
      err('Two or more properties are annotated with @id.', modelClass);
    }

    return ObjectInfo(
      dartName: modelClass.displayName,
      isarName: modelClass.isarName,
      accessor: modelClass.collectionAccessor,
      properties: properties,
      embeddedDartNames: _getEmbeddedDartNames(element),
    );
  }

  ObjectInfo analyzeEmbedded(Element element) {
    final constructor = _checkValidClass(element);
    final modelClass = element as ClassElement;

    if (constructor.parameters.any((e) => e.isRequired)) {
      err(
        'Constructors of embedded objects must not have required parameters.',
        constructor,
      );
    }

    final properties = <PropertyInfo>[];
    for (final propertyElement in modelClass.allAccessors) {
      final property = analyzePropertyInfo(propertyElement, constructor);
      properties.add(property);
    }
    _checkValidPropertiesConstructor(properties, constructor);

    /*final hasIndex = modelClass.allAccessors.any(
      (it) => it.indexAnnotations.isNotEmpty,
    );
    if (hasIndex) {
      err('Embedded objects must not have indexes.', modelClass);
    }*/

    if (properties.any((it) => it.isId)) {
      err('Embedded objects must not define an id.', modelClass);
    }

    return ObjectInfo(
      dartName: modelClass.displayName,
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
          if (names.add(type.displayName)) {
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
  ) {
    final dartType = property.type;
    final scalarDartType = dartType.scalarType;
    Map<String, dynamic>? enumMap;
    String? enumPropertyName;
    String? defaultEnumElement;

    late final PropertyType type;
    if (scalarDartType.element is EnumElement) {
      final enumeratedAnn = property.enumeratedAnnotation;
      if (enumeratedAnn == null) {
        err('Enum property must be annotated with @enumerated.', property);
      }

      final enumClass = scalarDartType.element! as EnumElement;
      final enumElements =
          enumClass.fields.where((f) => f.isEnumConstant).toList();
      defaultEnumElement = '${enumClass.name}.${enumElements.first.name}';

      if (enumeratedAnn.type == EnumType.ordinal) {
        type =
            dartType.isDartCoreList ? PropertyType.byteList : PropertyType.byte;
        enumMap = {
          for (var i = 0; i < enumElements.length; i++) enumElements[i].name: i,
        };
        enumPropertyName = 'index';
      } else if (enumeratedAnn.type == EnumType.name) {
        type = dartType.isDartCoreList
            ? PropertyType.stringList
            : PropertyType.string;
        enumMap = {
          for (final value in enumElements) value.name: value.name,
        };
        enumPropertyName = 'name';
      } else {
        enumPropertyName = enumeratedAnn.property;
        if (enumPropertyName == null) {
          err(
            'Enums with type EnumType.value must specify which property '
            'should be used.',
            property,
          );
        }
        final enumProperty = enumClass.getField(enumPropertyName);
        if (enumProperty == null || enumProperty.isEnumConstant) {
          err('Enum property "$enumProperty" does not exist.', property);
        } else if (enumProperty.nonSynthetic is PropertyAccessorElement) {
          err('Only fields are supported for enum properties', enumProperty);
        }

        final enumPropertyType = enumProperty.type.propertyType;
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
        for (final element in enumElements) {
          final property =
              element.computeConstantValue()!.getField(enumPropertyName)!;
          final propertyValue = property.toBoolValue() ??
              property.toIntValue() ??
              property.toDoubleValue() ??
              property.toStringValue();
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
      }
    } else {
      if (dartType.propertyType != null) {
        type = dartType.propertyType!;
      } else {
        err(
          'Unsupported type. Please annotate the property with @ignore.',
          property,
        );
      }
    }

    final nullable = dartType.nullabilitySuffix != NullabilitySuffix.none;

    final isId = property.hasIdAnnotation;
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
      dartName: property.displayName,
      isarName: property.isarName,
      typeClassName: dartType.scalarType.element!.name!,
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
      defaultValue: defaultEnumElement ??
          constructorParameter?.defaultValueCode ??
          _defaultValue(dartType),
      elementDefaultValue:
          type.isList ? _defaultValue(dartType.scalarType) : null,
      mode: mode,
      assignable: property.setter != null,
      constructorPosition: constructorPosition,
    );
  }
}

String _defaultValue(DartType type) {
  if (type.nullabilitySuffix == NullabilitySuffix.question) {
    return 'null';
  } else if (type.isDartCoreInt) {
    return '$nullInt';
  } else if (type.isDartCoreDouble) {
    return 'double.nan';
  } else if (type.isDartCoreBool) {
    return 'false';
  } else if (type.isDartCoreString) {
    return "''";
  } else if (type.isDartCoreList) {
    return 'const []';
  } else if (type.isDartCoreSet) {
    return 'const {}';
  } else if (type.isDartCoreMap) {
    return 'const {}';
  } else {
    return 'null';
  }
}
