import 'dart:async';
import 'dart:convert';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:isar_generator/src/helper.dart';
import 'package:isar_generator/src/object_info.dart';
import 'package:source_gen/source_gen.dart';
import 'package:isar/isar.dart';
import 'package:dartx/dartx.dart';

class IsarAnalyzer extends Builder {
  final _collectionAnnChecker = const TypeChecker.fromRuntime(Collection);
  final _extcollectionAnnChecker =
      const TypeChecker.fromRuntime(ExternalCollection);

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final resolver = buildStep.resolver;
    if (!await resolver.isLibrary(buildStep.inputId)) return;
    final libReader = LibraryReader(await buildStep.inputLibrary);

    final objects = libReader
        .annotatedWith(_collectionAnnChecker)
        .map((e) => generateObjectInfo(e.element))
        .whereNotNull()
        .toList();

    final externalObjects = libReader
        .annotatedWith(_extcollectionAnnChecker)
        .map((e) sync* {
          final annotations = _extcollectionAnnChecker.annotationsOf(e.element);
          for (var annotation in annotations) {
            final col = annotation.getField('collection')!.toTypeValue()!;
            var oi = generateObjectInfo(col.element!);
            if (oi != null) {
              final cls = col.element as ClassElement;
              yield oi.copyWith(
                imports: [...oi.imports, cls.location!.components[0]],
              );
            }
          }
        })
        .flatten()
        .whereNotNull();

    objects.addAll(externalObjects);

    if (objects.isEmpty) return;

    final objectsJson = objects.map((e) => e.toJson()).toList();
    final json = JsonEncoder().convert(objectsJson);
    await buildStep.writeAsString(
        buildStep.inputId.changeExtension('.isarobject.json'), json);
  }

  ObjectInfo? generateObjectInfo(Element element) {
    if (element is! ClassElement) {
      err('Only classes may be annotated with @Collection.', element);
    }

    final modelClass = element as ClassElement;
    final collectionAnn = getCollectionAnn(element)!;

    if (modelClass.isAbstract) {
      err('Class must not be abstract.', element);
    }

    if (!modelClass.isPublic) {
      err('Class must be public.', element);
    }

    final constructor =
        modelClass.constructors.firstOrNullWhere((c) => c.periodOffset == null);

    if (constructor == null) {
      err('Class needs an unnamed constructor.');
    }

    final isarName = getNameAnn(modelClass)?.name ?? modelClass.displayName;
    if (isarName.isEmpty) {
      err('Empty model names are not allowed.', modelClass);
    }

    final properties = <ObjectProperty>[];
    final links = <ObjectLink>[];
    final converterImports = <String>{};
    final allAccessors = {
      ...modelClass.accessors.mapNotNull((e) => e.variable),
      if (collectionAnn.inheritance)
        for (var supertype in modelClass.allSupertypes) ...[
          if (!supertype.isDartCoreObject)
            ...supertype.accessors.mapNotNull((e) => e.variable)
        ]
    };
    for (var propertyElement in allAccessors.where(checkField)) {
      if (hasIgnoreAnn(propertyElement)) {
        continue;
      }

      final converter = findTypeConverter(propertyElement);
      if (converter != null) {
        converterImports.add(converter.location!.components[0]);
      }

      if (propertyElement.type.element!.name == 'IsarLink' ||
          propertyElement.type.element!.name == 'IsarLinks') {
        final link = analyzeObjectLink(propertyElement, converter);
        if (link == null) continue;
        links.add(link);
      } else {
        final property = analyzeObjectProperty(
          propertyElement,
          converter,
          constructor!,
        );
        if (property == null) continue;
        properties.add(property);
      }
    }

    final indexes = <ObjectIndex>[];
    for (var propertyElement in modelClass.fields.where(checkField)) {
      if (links.any((it) => it.dartName == propertyElement.name)) continue;
      final index = analyzeObjectIndex(properties, propertyElement);
      if (index == null) continue;
      indexes.add(index);
    }
    checkDuplicateIndexes(element, indexes);

    var oidProperty = properties.firstOrNullWhere((it) => it.isId);
    if (oidProperty == null) {
      for (var i = 0; i < properties.length; i++) {
        final property = properties[i];
        if (property.isarName == 'id' &&
            property.converter == null &&
            property.isarType == IsarType.Long) {
          oidProperty = properties[i].copyWith(isId: true);
          properties[i] = oidProperty;
          break;
        }
      }
      if (oidProperty == null) {
        err('More than one property annotated with @Id().', element);
      }
    }

    if (oidProperty == null) {
      err('No property annotated with @Id().', element);
    }

    final sortedProperties = properties.sortedBy((p) {
      if (p.isId) {
        return -1; // Sort first
      }
      final index =
          constructor!.parameters.indexWhere((e) => e.name == p.dartName);
      return index == -1 ? 999999 : index;
    });

    final unknownConstructorParameter = constructor!.parameters
        .firstOrNullWhere((p) =>
            p.isNotOptional && properties.none((e) => e.dartName == p.name));
    if (unknownConstructorParameter != null) {
      err('Constructor parameter does not match a property.',
          unknownConstructorParameter);
    }

    final modelInfo = ObjectInfo(
      dartName: modelClass.displayName,
      isarName: isarName,
      properties: sortedProperties,
      indexes: indexes,
      links: links,
      imports: converterImports.toList(),
    );

    return modelInfo;
  }

  ClassElement? findTypeConverter(PropertyInducingElement property) {
    final annotations = getTypeConverterAnns(property);
    annotations.addAll(getTypeConverterAnns(property.enclosingElement!));

    for (var annotation in annotations) {
      final cls = annotation.type!.element as ClassElement;
      final dartType = cls.supertype!.typeArguments[0];
      if (dartType == property.type) {
        return cls;
      }
    }

    return null;
  }

  ObjectProperty? analyzeObjectProperty(PropertyInducingElement property,
      ClassElement? converter, ConstructorElement constructor) {
    if (!property.isPublic || property.isStatic) {
      return null;
    }

    final nullable = property.type.nullabilitySuffix != NullabilitySuffix.none;
    var elementNullable = false;
    if (property.type is ParameterizedType) {
      final typeArguments = (property.type as ParameterizedType).typeArguments;
      if (typeArguments.isNotEmpty) {
        final listType = typeArguments[0];
        elementNullable = listType.nullabilitySuffix != NullabilitySuffix.none;
      }
    }

    final nameAnn = getNameAnn(property);
    if (nameAnn != null && nameAnn.name.isEmpty) {
      err('Empty property names are not allowed.', property);
    }
    var isarName = nameAnn?.name ?? property.displayName;

    IsarType? isarType;
    if (converter == null) {
      final size32 = hasSize32Ann(property);
      isarType = getIsarType(property.type, size32, property);
    } else {
      final isarDartType = converter.supertype!.typeArguments[1];
      final size32 = hasSize32Ann(converter);
      isarType = getIsarType(isarDartType, size32, converter);
    }

    if (isarType == null) {
      return null;
    }

    final isId = hasIdAnn(property);
    if (isId) {
      if (converter != null) {
        err('Converters are not allowed for ids.', property);
      } else if (isarType != IsarType.Long) {
        err('Only int ids are allowed', property);
      }
    }

    var type = property.type.getDisplayString(withNullability: true);
    if (type.endsWith('*')) {
      type = type.removeSuffix('*') + '?';
    }

    final constructorParameter =
        constructor.parameters.firstOrNullWhere((p) => p.name == property.name);
    int? constructorPosition;
    late PropertyDeser deserialize;
    if (constructorParameter != null) {
      if (constructorParameter.type != property.type) {
        err('Constructor parameter type does not match property type',
            constructorParameter);
      }
      deserialize = constructorParameter.isNamed
          ? PropertyDeser.NamedParam
          : PropertyDeser.PositionalParam;
      constructorPosition =
          constructor.parameters.indexOf(constructorParameter);
    } else {
      deserialize =
          property.setter == null ? PropertyDeser.None : PropertyDeser.Assign;
    }
    return ObjectProperty(
      dartName: property.displayName,
      isarName: isarName,
      dartType: type,
      isarType: isarType,
      isId: isId,
      converter: converter?.name,
      nullable: nullable,
      elementNullable: elementNullable,
      deserialize: deserialize,
      constructorPosition: constructorPosition,
    );
  }

  IsarType? getIsarType(DartType type, bool size32, Element element) {
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
      if (typeArguments.isNotEmpty) {
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
        } else if (isDateTime(listType.element!)) {
          return IsarType.DateTimeList;
        }
      }
    } else if (isDateTime(type.element!)) {
      return IsarType.DateTime;
    } else if (isUint8List(type.element!)) {
      return IsarType.Bytes;
    }
  }

  ObjectLink? analyzeObjectLink(
      PropertyInducingElement property, ClassElement? converter) {
    if (!property.isPublic || property.isStatic || hasIgnoreAnn(property)) {
      return null;
    }

    if (converter != null) {
      err('Converters are not supported for links.', property);
    }

    final isLinks = property.type.element!.name == 'IsarLinks';

    final type = property.type as ParameterizedType;
    if (type.typeArguments.length != 1) {
      err('Illegal type arguments for link.', property);
    }
    final linkType = type.typeArguments[0];
    if (linkType.nullabilitySuffix != NullabilitySuffix.none) {
      err('Links type must not be nullable.', property);
    }

    final nameAnn = getNameAnn(property);
    if (nameAnn != null && nameAnn.name.isEmpty) {
      err('Empty link names are not allowed.', property);
    }
    var isarName = nameAnn?.name ?? property.displayName;

    final backlinkAnn = getBacklinkAnn(property);
    return ObjectLink(
      dartName: property.displayName,
      isarName: isarName,
      targetDartName: backlinkAnn?.to,
      targetCollectionDartName: linkType.element!.name!,
      links: isLinks,
      backlink: backlinkAnn != null,
    );
  }

  ObjectIndex? analyzeObjectIndex(
      List<ObjectProperty> properties, FieldElement element) {
    final property = properties.firstWhere((it) => it.dartName == element.name);

    final indexAnns = getIndexAnns(element).toList();
    if (indexAnns.isEmpty) {
      return null;
    } else if (indexAnns.length > 1) {
      err('Property must not have more than one @Index annotations.', element);
    }

    final index = indexAnns[0];

    if (!index.unique && index.replace) {
      err('Only unique indexes may replace existing entries', element);
    }

    final indexProperties = <ObjectIndexProperty>[];
    final defaultIndexType =
        property.isarType == IsarType.String ? IndexType.hash : IndexType.value;
    final defaultCaseSensitive =
        property.isarType == IsarType.String ? true : null;
    indexProperties.add(ObjectIndexProperty(
      property: property,
      indexType: index.indexType ?? defaultIndexType,
      caseSensitive: index.caseSensitive ?? defaultCaseSensitive,
    ));
    for (var c in index.composite) {
      final compositeProperty =
          properties.firstOrNullWhere((it) => it.dartName == c.property);
      if (compositeProperty == null) {
        err('Property does not exist: "${c.property}".', element);
      } else {
        indexProperties.add(ObjectIndexProperty(
          property: compositeProperty,
          indexType: c.indexType ?? defaultIndexType,
          caseSensitive: c.caseSensitive ?? defaultCaseSensitive,
        ));
      }
    }

    if (indexProperties.map((it) => it.property.isarName).distinct().length !=
        indexProperties.length) {
      err('Composite index contains duplicate properties.', element);
    }

    for (var i = 0; i < indexProperties.length; i++) {
      final indexProperty = indexProperties[i];
      if (indexProperty.property.isarType.isDynamic &&
          indexProperty.property.isarType != IsarType.String) {
        err('This type does not support indexes.', element);
      }
      if (property.isarType == IsarType.String) {
        if ((indexProperty.indexType == IndexType.value ||
                indexProperty.indexType == IndexType.words) &&
            i != indexProperties.lastIndex) {
          err('Only the last property of a composite index may use IndexType.value or IndexType.words.',
              element);
        }
      } else if (indexProperty.indexType != IndexType.value) {
        err('Only String indices may have a IndexType other than IndexType.value ${indexProperty.indexType}.',
            element);
      }
    }

    return ObjectIndex(
      properties: indexProperties,
      unique: index.unique,
      replace: index.replace,
    );
  }

  void checkDuplicateIndexes(Element element, List<ObjectIndex> indexes) {
    for (var index in indexes) {
      for (var index2 in indexes) {
        if (identical(index, index2)) continue;
        if (index.properties.length <= index2.properties.length) {
          final indexPropertyNames =
              index.properties.map((it) => it.property.isarName);
          final index2PropertyNames = index2.properties
              .take(index.properties.length)
              .map((it) => it.property.isarName);
          if (indexPropertyNames.contentEquals(index2PropertyNames)) {
            err('There are multiple indexes with the prefix "${indexPropertyNames.join(', ')}"',
                element);
          }
        }
      }
    }
  }

  bool checkField(PropertyInducingElement element) {
    // Check if the element is a pure getter (no setter defined)
    if (element.setter == null) {
      return false;
    }

    // Check if the element's getter and setter are not synthetic (the element is not a field).
    // This means that the getter and the setter are explicitly defined in the code.
    if (element.getter?.isSynthetic == false &&
        element.setter?.isSynthetic == false) {
      return false;
    }

    // This is surely a field.
    return true;
  }

  @override
  final buildExtensions = {
    '.dart': ['.isarobject.json']
  };
}
