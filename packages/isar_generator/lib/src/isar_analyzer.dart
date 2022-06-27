import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dartx/dartx.dart';
import 'package:isar/isar.dart';

import 'package:isar_generator/src/helper.dart';
import 'package:isar_generator/src/isar_type.dart';
import 'package:isar_generator/src/object_info.dart';

class IsarAnalyzer {
  ObjectInfo analyze(Element modelClass) {
    if (modelClass is! ClassElement ||
        modelClass.isEnum ||
        modelClass.isMixin) {
      err('Only classes may be annotated with @Collection.', modelClass);
    }

    if (modelClass.isAbstract) {
      err('Class must not be abstract.', modelClass);
    }

    if (!modelClass.isPublic) {
      err('Class must be public.', modelClass);
    }

    final constructor = modelClass.constructors
        .firstOrNullWhere((ConstructorElement c) => c.periodOffset == null);

    if (constructor == null) {
      err('Class needs an unnamed constructor.');
    }

    final properties = <ObjectProperty>[];
    final links = <ObjectLink>[];
    for (final propertyElement in modelClass.allAccessors) {
      final link = analyzeObjectLink(propertyElement);
      if (link != null) {
        links.add(link);
      } else {
        final property = analyzeObjectProperty(
          propertyElement,
          constructor,
        );
        if (property == null) {
          continue;
        }
        properties.add(property);
      }
    }
    if (properties.map((e) => e.isarName).distinct().length !=
        properties.length) {
      err('Two or more properties have the same name.', modelClass);
    }
    if (links.map((e) => e.isarName).distinct().length != links.length) {
      err('Two or more links have the same name.', modelClass);
    }

    final indexes = <ObjectIndex>[];
    for (final propertyElement in modelClass.allAccessors) {
      indexes.addAll(analyzeObjectIndex(properties, propertyElement));
    }
    if (indexes.map((e) => e.name).distinct().length != indexes.length) {
      err('Two or more indexes have the same name.', modelClass);
    }

    final idProperties = properties.where((ObjectProperty it) => it.isId);
    var idProperty = idProperties.firstOrNull;
    if (idProperty == null) {
      for (var i = 0; i < properties.length; i++) {
        final property = properties[i];
        if (property.isarName == 'id' &&
            property.converter == null &&
            property.isarType == IsarType.long) {
          idProperty = properties[i].copyWithIsId(true);
          properties[i] = idProperty;
          break;
        }
      }
    }

    if (idProperty == null) {
      err('No int property named "id" or annotated with @Id().', modelClass);
    } else if (idProperties.length > 1) {
      err('Two or more properties annotated with @Id().', modelClass);
    } else if (idProperty.converter != null) {
      err('Converters are not allowed for ids.', modelClass);
    } else if (idProperty.isarType != IsarType.long) {
      err('Only int ids are allowed', modelClass);
    }

    final unknownConstructorParameter = constructor.parameters.firstOrNullWhere(
      (p) => p.isRequired && properties.none((e) => e.dartName == p.name),
    );
    if (unknownConstructorParameter != null) {
      err(
        'Constructor parameter does not match a property.',
        unknownConstructorParameter,
      );
    }

    final sortedLinks =
        links.where((it) => !it.backlink).sortedBy((it) => it.isarName);
    final sortedBacklinks = links
        .where((it) => it.backlink)
        .sortedBy((it) => it.targetCollectionIsarName)
        .thenBy((it) => it.targetIsarName!);
    return ObjectInfo(
      dartName: modelClass.displayName,
      isarName: modelClass.isarName,
      accessor: modelClass.collectionAccessor,
      properties: properties.sortedBy((e) => e.isarName),
      indexes: indexes.sortedBy((e) => e.name),
      links: [...sortedLinks, ...sortedBacklinks],
    );
  }

  ObjectProperty? analyzeObjectProperty(
    PropertyInducingElement property,
    ConstructorElement constructor,
  ) {
    final converter = property.typeConverter;

    late final DartType isarDartType;
    if (converter == null) {
      isarDartType = property.type;
    } else {
      isarDartType = converter.supertype!.typeArguments[1];
    }

    final isarType = getIsarType(isarDartType, converter ?? property);

    final nullable = isarDartType.nullabilitySuffix != NullabilitySuffix.none;
    var elementNullable = false;
    if (isarDartType is ParameterizedType) {
      final typeArguments = isarDartType.typeArguments;
      if (typeArguments.isNotEmpty) {
        final listType = typeArguments[0];
        elementNullable = listType.nullabilitySuffix != NullabilitySuffix.none;
      }
    }

    if (isarType == null) {
      return null;
    }

    final constructorParameter =
        constructor.parameters.firstOrNullWhere((p) => p.name == property.name);
    int? constructorPosition;
    late PropertyDeser deserialize;
    if (constructorParameter != null) {
      if (constructorParameter.type != property.type) {
        err(
          'Constructor parameter type does not match property type',
          constructorParameter,
        );
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

    var dartTypeStr = property.type.getDisplayString(withNullability: true);
    dartTypeStr = dartTypeStr.replaceAll('*', '?');

    return ObjectProperty(
      dartName: property.displayName,
      isarName: property.isarName,
      dartType: dartTypeStr,
      isarType: isarType,
      isId: property.hasIdAnnotation,
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

    if (!isLink && !isLinks) {
      return null;
    }

    if (property.type.nullabilitySuffix != NullabilitySuffix.none) {
      err('Link properties must not be nullable.', property);
    } else if (property.isLate) {
      err('Link properties must not be late.', property);
    }

    final type = property.type as ParameterizedType;
    if (type.typeArguments.length != 1) {
      err('Illegal type arguments for link.', property);
    }
    final linkType = type.typeArguments[0];
    if (linkType.nullabilitySuffix != NullabilitySuffix.none) {
      err('Links type must not be nullable.', property);
    }

    final targetCol = linkType.element! as ClassElement;

    if (targetCol.collectionAnnotation == null) {
      err('Link target is not annotated with @Collection()');
    }

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
      targetCollectionAccessor: targetCol.collectionAccessor,
      links: isLinks,
      backlink: backlinkAnn != null,
    );
  }

  Iterable<ObjectIndex> analyzeObjectIndex(
    List<ObjectProperty> properties,
    PropertyInducingElement element,
  ) sync* {
    final property =
        properties.firstOrNullWhere((it) => it.dartName == element.name);
    if (property == null || property.isId) {
      return;
    }

    for (final index in element.indexAnnotations) {
      final indexProperties = <ObjectIndexProperty>[];

      late IndexType defaultType;
      if (property.isarType == IsarType.string ||
          property.isarType == IsarType.bytes) {
        defaultType = IndexType.hash;
      } else if (property.isarType == IsarType.stringList) {
        defaultType = IndexType.hashElements;
      } else {
        defaultType = IndexType.value;
      }
      indexProperties.add(
        ObjectIndexProperty(
          property: property,
          type: index.type ?? defaultType,
          caseSensitive:
              index.caseSensitive ?? property.isarType.containsString,
        ),
      );
      for (final c in index.composite) {
        final compositeProperty =
            properties.firstOrNullWhere((it) => it.dartName == c.property);
        if (compositeProperty == null) {
          err('Property does not exist: "${c.property}".', element);
        } else if (compositeProperty.isId) {
          err('The Id property cannot be part of composite indexes.', element);
        } else {
          indexProperties.add(
            ObjectIndexProperty(
              property: compositeProperty,
              type: c.type ??
                  (compositeProperty.isarType.isDynamic
                      ? IndexType.hash
                      : IndexType.value),
              caseSensitive:
                  c.caseSensitive ?? compositeProperty.isarType.containsString,
            ),
          );
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
          err(
            'Only the last property of a composite index may be a '
            'double value.',
            element,
          );
        }
        if (indexProperty.isarType == IsarType.string) {
          if (indexProperty.type != IndexType.hash &&
              i != indexProperties.lastIndex) {
            err(
              'Only the last property of a composite index may be a '
              'non-hashed String.',
              element,
            );
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

      if (!index.unique && index.replace) {
        err('Only unique indexes can replace.', element);
      }

      final name = index.name ??
          indexProperties.map((e) => e.property.isarName).join('_');
      checkIsarName(name, element);

      yield ObjectIndex(
        name: name,
        properties: indexProperties,
        unique: index.unique,
        replace: index.replace,
      );
    }
  }
}
