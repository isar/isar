import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:dartx/dartx.dart';
import 'package:isar/isar.dart';
import 'package:source_gen/source_gen.dart';

const TypeChecker _collectionChecker = TypeChecker.fromRuntime(Collection);
const TypeChecker _ignoreChecker = TypeChecker.fromRuntime(Ignore);
const TypeChecker _nameChecker = TypeChecker.fromRuntime(Name);
const TypeChecker _indexChecker = TypeChecker.fromRuntime(Index);
const TypeChecker _backlinkChecker = TypeChecker.fromRuntime(Backlink);
const TypeChecker _typeConverterChecker =
    TypeChecker.fromRuntime(TypeConverter);

extension ClassElementX on ClassElement {
  bool get hasZeroArgsConstructor {
    return constructors.any(
      (ConstructorElement c) =>
          c.isPublic &&
          !c.parameters.any((ParameterElement p) => !p.isOptional),
    );
  }

  List<PropertyInducingElement> get allAccessors {
    return [
      ...accessors.mapNotNull((e) => e.variable),
      if (collectionAnnotation!.inheritance)
        for (InterfaceType supertype in allSupertypes) ...[
          if (!supertype.isDartCoreObject)
            ...supertype.accessors.mapNotNull((e) => e.variable)
        ]
    ]
        .where(
          (PropertyInducingElement e) =>
              e.isPublic &&
              !e.isStatic &&
              !_ignoreChecker.hasAnnotationOf(e.nonSynthetic),
        )
        .distinctBy((e) => e.name)
        .toList();
  }
}

extension PropertyElementX on PropertyInducingElement {
  ClassElement? get typeConverter {
    Element? element = this;
    while (element != null) {
      final elementAnns =
          _typeConverterChecker.annotationsOf(element.nonSynthetic);
      for (final ann in elementAnns) {
        final reviver = ConstantReader(ann).revive();
        if (reviver.namedArguments.isNotEmpty ||
            reviver.positionalArguments.isNotEmpty) {
          err(
            'TypeConverters with constructor arguments are not supported.',
            ann.type!.element,
          );
        }

        // ignore: cast_nullable_to_non_nullable
        final cls = ann.type!.element as ClassElement;
        final adapterDartType = cls.supertype!.typeArguments[0];
        final checker = TypeChecker.fromStatic(adapterDartType);
        final nullabilityMatches =
            adapterDartType.nullabilitySuffix != NullabilitySuffix.none ||
                type.nullabilitySuffix == NullabilitySuffix.none;
        if (checker.isAssignableFromType(type)) {
          if (nullabilityMatches) {
            return cls;
          } else {
            err(
              'The TypeConverter has incompatible nullability.',
              ann.type!.element,
            );
          }
        }
      }
      element = element.enclosingElement;
    }
    return null;
  }

  Backlink? get backlinkAnnotation {
    final ann = _backlinkChecker.firstAnnotationOfExact(nonSynthetic);
    if (ann == null) {
      return null;
    }
    return Backlink(to: ann.getField('to')!.toStringValue()!);
  }

  List<Index> get indexAnnotations {
    return _indexChecker.annotationsOfExact(nonSynthetic).map((DartObject ann) {
      final rawComposite = ann.getField('composite')!.toListValue();
      final composite = <CompositeIndex>[];
      if (rawComposite != null) {
        for (final c in rawComposite) {
          final indexTypeField = c.getField('type')!;
          IndexType? indexType;
          if (!indexTypeField.isNull) {
            final indexTypeIndex =
                indexTypeField.getField('index')!.toIntValue()!;
            indexType = IndexType.values[indexTypeIndex];
          }
          composite.add(
            CompositeIndex(
              c.getField('property')!.toStringValue()!,
              type: indexType,
              caseSensitive: c.getField('caseSensitive')!.toBoolValue(),
            ),
          );
        }
      }
      final indexTypeField = ann.getField('type')!;
      IndexType? indexType;
      if (!indexTypeField.isNull) {
        final indexTypeIndex = indexTypeField.getField('index')!.toIntValue()!;
        indexType = IndexType.values[indexTypeIndex];
      }
      return Index(
        name: ann.getField('name')!.toStringValue(),
        composite: composite,
        unique: ann.getField('unique')!.toBoolValue()!,
        replace: ann.getField('replace')!.toBoolValue()!,
        type: indexType,
        caseSensitive: ann.getField('caseSensitive')!.toBoolValue(),
      );
    }).toList();
  }
}

extension ElementX on Element {
  String get isarName {
    final ann = _nameChecker.firstAnnotationOfExact(nonSynthetic);
    late String name;
    if (ann == null) {
      name = displayName;
    } else {
      name = ann.getField('name')!.toStringValue()!;
    }
    checkIsarName(name, this);
    return name;
  }

  Collection? get collectionAnnotation {
    final ann = _collectionChecker.firstAnnotationOfExact(nonSynthetic);
    if (ann == null) {
      return null;
    }
    return Collection(
      inheritance: ann.getField('inheritance')!.toBoolValue()!,
      accessor: ann.getField('accessor')!.toStringValue(),
    );
  }

  String get collectionAccessor {
    var accessor = collectionAnnotation?.accessor;
    if (accessor != null) {
      return accessor;
    }

    accessor = displayName.decapitalize();
    if (!accessor.endsWith('s')) {
      accessor += 's';
    }

    return accessor;
  }
}

void checkIsarName(String name, Element element) {
  if (name.isBlank || name.startsWith('_')) {
    err('Names must not be blank or start with "_".', element);
  }
}

Never err(String msg, [Element? element]) {
  throw InvalidGenerationSourceError(msg, element: element);
}
