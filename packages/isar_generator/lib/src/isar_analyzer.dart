import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:isar/isar.dart';
import 'package:isar_generator/src/helper.dart';
import 'package:isar_generator/src/object_info.dart';
import 'package:dartx/dartx.dart';

import 'isar_type.dart';

class IsarAnalyzer {
  ObjectInfo analyze(Element modelClass) {
    if (modelClass is! ClassElement) {
      err('Only classes may be annotated with @Collection.', modelClass);
    }

    if (modelClass.isAbstract) {
      err('Class must not be abstract.', modelClass);
    }

    if (!modelClass.isPublic) {
      err('Class must be public.', modelClass);
    }

    final constructor =
        modelClass.constructors.firstOrNullWhere((c) => c.periodOffset == null);

    if (constructor == null) {
      err('Class needs an unnamed constructor.');
    }

    final properties = <ObjectProperty>[];
    final links = <ObjectLink>[];
    for (var propertyElement in modelClass.allAccessors) {
      final link = analyzeObjectLink(propertyElement);
      if (link != null) {
        links.add(link);
      } else {
        final property = analyzeObjectProperty(
          propertyElement,
          constructor,
        );
        if (property == null) continue;
        properties.add(property);
      }
    }

    final indexes = <ObjectIndex>[];
    for (var propertyElement in modelClass.allAccessors) {
      indexes.addAll(analyzeObjectIndex(properties, propertyElement));
    }
    if (indexes.map((e) => e.name).distinct().length != indexes.length) {
      err('Two or more indexes have the same name.', modelClass);
    }

    var idProperty = properties.firstOrNullWhere((it) => it.isId);
    if (idProperty == null) {
      for (var i = 0; i < properties.length; i++) {
        final property = properties[i];
        if (property.isarName == 'id' &&
            property.converter == null &&
            property.isarType == IsarType.long) {
          idProperty = properties[i].copyWith(isId: true);
          properties[i] = idProperty;
          break;
        }
      }
    }

    if (idProperty == null) {
      err('No property annotated with @Id().', modelClass);
    }

    final unknownConstructorParameter = constructor.parameters.firstOrNullWhere(
        (p) => p.isNotOptional && properties.none((e) => e.dartName == p.name));
    if (unknownConstructorParameter != null) {
      err('Constructor parameter does not match a property.',
          unknownConstructorParameter);
    }

    final accessor = modelClass.collectionAnnotation?.accessor ??
        '${modelClass.displayName.decapitalize()}s';
    final modelInfo = ObjectInfo(
      dartName: modelClass.displayName,
      isarName: modelClass.isarName,
      accessor: accessor,
      properties: properties.sortedBy((e) => e.isarName),
      indexes: indexes.sortedBy((e) => e.name),
      links: links
          .sortedBy((e) => e.targetCollectionIsarName)
          .thenBy((e) => e.targetIsarName ?? ''),
    );

    return modelInfo;
  }

  ObjectProperty? analyzeObjectProperty(
      PropertyInducingElement property, ConstructorElement constructor) {
    final nullable = property.type.nullabilitySuffix != NullabilitySuffix.none;
    var elementNullable = false;
    if (property.type is ParameterizedType) {
      final typeArguments = (property.type as ParameterizedType).typeArguments;
      if (typeArguments.isNotEmpty) {
        final listType = typeArguments[0];
        elementNullable = listType.nullabilitySuffix != NullabilitySuffix.none;
      }
    }

    final converter = property.typeConverter;
    IsarType? isarType;
    if (converter == null) {
      isarType = getIsarType(property.type, property);
    } else {
      final isarDartType = converter.supertype!.typeArguments[1];
      isarType = getIsarType(isarDartType, converter);
    }

    if (isarType == null) {
      return null;
    }

    final isId = property.hasIdAnnotation;
    if (isId) {
      if (converter != null) {
        err('Converters are not allowed for ids.', property);
      } else if (isarType != IsarType.long) {
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
          ? PropertyDeser.namedParam
          : PropertyDeser.positionalParam;
      constructorPosition =
          constructor.parameters.indexOf(constructorParameter);
    } else {
      deserialize =
          property.setter == null ? PropertyDeser.none : PropertyDeser.assign;
    }
    return ObjectProperty(
      dartName: property.displayName,
      isarName: property.isarName,
      dartType: type,
      isarType: isarType,
      isId: isId,
      converter: converter?.name,
      nullable: nullable,
      elementNullable: elementNullable,
      deserialize: deserialize,
      assignable: property.setter != null,
      constructorPosition: constructorPosition,
    );
  }

  ObjectLink? analyzeObjectLink(PropertyInducingElement property) {
    final isLink = property.type.element!.name == 'IsarLink';
    final isLinks = property.type.element!.name == 'IsarLinks';

    if (!isLink && !isLinks) return null;

    final type = property.type as ParameterizedType;
    if (type.typeArguments.length != 1) {
      err('Illegal type arguments for link.', property);
    }
    final linkType = type.typeArguments[0];
    if (linkType.nullabilitySuffix != NullabilitySuffix.none) {
      err('Links type must not be nullable.', property);
    }

    final targetCol = linkType.element! as ClassElement;

    final backlinkAnn = property.backlinkAnnotation;
    String? targetIsarName;
    if (backlinkAnn != null) {
      final targetProperty = targetCol.allAccessors
          .firstOrNullWhere((e) => e.displayName == backlinkAnn.to);
      if (targetProperty == null) {
        err('Target of Backlink does not exist', property);
      } else if (targetProperty.backlinkAnnotation != null) {
        err('Target of Backlink is also a backlink', property);
      }
      final targetLink = analyzeObjectLink(targetProperty);
      if (targetLink == null) {
        err('Target of backlink is not a link', property);
      }
      targetIsarName = targetLink.isarName;
    }

    return ObjectLink(
      dartName: property.displayName,
      isarName: property.isarName,
      targetIsarName: targetIsarName,
      targetCollectionDartName: linkType.element!.name!,
      targetCollectionIsarName: targetCol.isarName,
      links: isLinks,
      backlink: backlinkAnn != null,
    );
  }

  Iterable<ObjectIndex> analyzeObjectIndex(
      List<ObjectProperty> properties, PropertyInducingElement element) sync* {
    final property =
        properties.firstOrNullWhere((it) => it.dartName == element.name);
    if (property == null) return;

    for (var index in element.indexAnnotations) {
      final indexProperties = <ObjectIndexProperty>[];

      indexProperties.add(ObjectIndexProperty(
        property: property,
        type: index.type ??
            (property.isarType == IsarType.string
                ? IndexType.hash
                : property.isarType == IsarType.stringList
                    ? IndexType.hashElements
                    : IndexType.value),
        caseSensitive: index.caseSensitive ?? property.isarType.containsString,
      ));
      for (var c in index.composite) {
        final compositeProperty =
            properties.firstOrNullWhere((it) => it.dartName == c.property);
        if (compositeProperty == null) {
          err('Property does not exist: "${c.property}".', element);
        } else {
          indexProperties.add(ObjectIndexProperty(
            property: compositeProperty,
            type: c.type ??
                (compositeProperty.isarType == IsarType.string
                    ? IndexType.hash
                    : IndexType.value),
            caseSensitive:
                c.caseSensitive ?? compositeProperty.isarType.containsString,
          ));
        }
      }

      if (indexProperties.map((it) => it.property.isarName).distinct().length !=
          indexProperties.length) {
        err('Composite index contains duplicate properties.', element);
      }

      for (var i = 0; i < indexProperties.length; i++) {
        final indexProperty = indexProperties[i];
        if (indexProperty.isarType.isList &&
            indexProperty.type != IndexType.hash &&
            indexProperties.length > 1) {
          err('Composite indexes do not support non-hashed lists.', element);
        }
        if (property.isarType.containsFloat && i != indexProperties.lastIndex) {
          err('Only the last property of a composite index may be a double value.',
              element);
        }
        if (property.isarType == IsarType.string) {
          if (indexProperty.type != IndexType.hash &&
              i != indexProperties.lastIndex) {
            err('Only the last property of a composite index may be a non-hashed String.',
                element);
          }
        }
        if (indexProperty.type != IndexType.value) {
          if (!indexProperty.isarType.isDynamic) {
            err('Only Strings and Lists may be hashed.', element);
          } else if (indexProperty.isarType.containsFloat) {
            err('List<double> may must not be hashed.', element);
          }
        }
        if (indexProperty.isarType != IsarType.stringList &&
            indexProperty.type == IndexType.hashElements) {
          err('Only String lists may have hashed elements.', element);
        }
        if (indexProperty.isarType == IsarType.bytes &&
            indexProperty.type != IndexType.hash) {
          err('Bytes indexes need to be hashed.', element);
        }
      }

      final name = index.name ??
          indexProperties.map((e) => e.property.isarName).join('_');
      checkIsarName(name, element);

      yield ObjectIndex(
        name: name,
        properties: indexProperties,
        unique: index.unique,
      );
    }
  }
}
