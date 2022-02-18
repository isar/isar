import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:dartx/dartx.dart';
import 'package:source_gen/source_gen.dart';
import 'package:isar/isar.dart';

final _collectionChecker = const TypeChecker.fromRuntime(Collection);
final _ignoreChecker = const TypeChecker.fromRuntime(Ignore);
final _nameChecker = const TypeChecker.fromRuntime(Name);
final _indexChecker = const TypeChecker.fromRuntime(Index);
final _oidKeyChecker = const TypeChecker.fromRuntime(Id);
final _backlinkChecker = const TypeChecker.fromRuntime(Backlink);
final _typeConverterChecker = const TypeChecker.fromRuntime(TypeConverter);

extension ClassElementX on ClassElement {
  bool get hasZeroArgsConstructor {
    return constructors
        .any((c) => c.isPublic && !c.parameters.any((p) => !p.isOptional));
  }

  Collection? get collectionAnnotation {
    var ann = _collectionChecker.firstAnnotationOfExact(nonSynthetic);
    if (ann == null) return null;
    return Collection(
      inheritance: ann.getField('inheritance')!.toBoolValue()!,
      accessor: ann.getField('accessor')!.toStringValue(),
    );
  }

  String get collectionAccessor {
    return collectionAnnotation?.accessor ?? '${displayName.decapitalize()}s';
  }

  List<PropertyInducingElement> get allAccessors {
    return [
      ...accessors.mapNotNull((e) => e.variable),
      if (collectionAnnotation!.inheritance)
        for (var supertype in allSupertypes) ...[
          if (!supertype.isDartCoreObject)
            ...supertype.accessors.mapNotNull((e) => e.variable)
        ]
    ]
        .where(
          (e) =>
              e.isPublic &&
              !e.isStatic &&
              !_ignoreChecker.hasAnnotationOf(e.nonSynthetic),
        )
        .distinctBy((e) => e.name)
        .toList();
  }
}

extension PropertyElementX on PropertyInducingElement {
  bool get hasIdAnnotation {
    return _oidKeyChecker.hasAnnotationOfExact(nonSynthetic);
  }

  ClassElement? get typeConverter {
    Element? element = this;
    while (element != null) {
      final elementAnns =
          _typeConverterChecker.annotationsOf(element.nonSynthetic);
      for (var ann in elementAnns) {
        final reviver = ConstantReader(ann).revive();
        if (reviver.namedArguments.isNotEmpty ||
            reviver.positionalArguments.isNotEmpty) {
          err(
            'TypeConverters with constructor arguments are not supported.',
            ann.type!.element,
          );
        }

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
    var ann = _backlinkChecker.firstAnnotationOfExact(nonSynthetic);
    if (ann == null) return null;
    return Backlink(to: ann.getField('to')!.toStringValue()!);
  }

  List<Index> get indexAnnotations {
    return _indexChecker.annotationsOfExact(nonSynthetic).map((ann) {
      var rawComposite = ann.getField('composite')!.toListValue();
      final composite = <CompositeIndex>[];
      if (rawComposite != null) {
        for (var c in rawComposite) {
          final indexTypeField = c.getField('type')!;
          IndexType? indexType;
          if (!indexTypeField.isNull) {
            final indexTypeIndex =
                indexTypeField.getField('index')!.toIntValue()!;
            indexType = IndexType.values[indexTypeIndex];
          }
          composite.add(CompositeIndex(
            c.getField('property')!.toStringValue()!,
            type: indexType,
            caseSensitive: c.getField('caseSensitive')!.toBoolValue(),
          ));
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
        type: indexType,
        caseSensitive: ann.getField('caseSensitive')!.toBoolValue(),
      );
    }).toList();
  }
}

extension ElementX on Element {
  String get isarName {
    var ann = _nameChecker.firstAnnotationOfExact(nonSynthetic);
    late String name;
    if (ann == null) {
      name = displayName;
    } else {
      name = ann.getField('name')!.toStringValue()!;
    }
    checkIsarName(name, this);
    return name;
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

extension StringEsc on String {
  String get esc => replaceAll('\$', '\\\$');
}
