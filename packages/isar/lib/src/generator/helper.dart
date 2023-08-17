part of isar_generator;

const TypeChecker _collectionChecker = TypeChecker.fromRuntime(Collection);
const TypeChecker _embeddedChecker = TypeChecker.fromRuntime(Embedded);
const TypeChecker _enumPropertyChecker = TypeChecker.fromRuntime(EnumValue);
const TypeChecker _idChecker = TypeChecker.fromRuntime(Id);
const TypeChecker _ignoreChecker = TypeChecker.fromRuntime(Ignore);
const TypeChecker _nameChecker = TypeChecker.fromRuntime(Name);
const TypeChecker _indexChecker = TypeChecker.fromRuntime(Index);
const TypeChecker _utcChecker = TypeChecker.fromRuntime(Utc);

extension on ClassElement {
  List<PropertyInducingElement> get allAccessors {
    final ignoreFields =
        collectionAnnotation?.ignore ?? embeddedAnnotation!.ignore;
    final allAccessors = [
      ...accessors.map((e) => e.variable),
      if (collectionAnnotation?.inheritance ?? embeddedAnnotation!.inheritance)
        for (final supertype in allSupertypes) ...[
          if (!supertype.isDartCoreObject)
            ...supertype.accessors.map((e) => e.variable),
        ],
    ];

    final usableAccessors = allAccessors.where(
      (e) =>
          e.isPublic &&
          !e.isStatic &&
          !_ignoreChecker.hasAnnotationOf(e.nonSynthetic) &&
          !ignoreFields.contains(e.name) &&
          e.name != 'hashCode',
    );

    final uniqueAccessors = <String, PropertyInducingElement>{};
    for (final accessor in usableAccessors) {
      uniqueAccessors[accessor.name] = accessor;
    }
    return uniqueAccessors.values.toList();
  }
}

extension on PropertyInducingElement {
  bool get hasIdAnnotation {
    final ann = _idChecker.firstAnnotationOfExact(nonSynthetic);
    return ann != null;
  }

  bool get hasUtcAnnotation {
    final ann = _utcChecker.firstAnnotationOfExact(nonSynthetic);
    return ann != null;
  }

  List<Index> get indexAnnotations {
    return _indexChecker.annotationsOfExact(nonSynthetic).map((ann) {
      return Index(
        name: ann.getField('name')!.toStringValue(),
        composite: ann
            .getField('composite')!
            .toListValue()!
            .map((e) => e.toStringValue()!)
            .toList(),
        unique: ann.getField('unique')!.toBoolValue()!,
        hash: ann.getField('hash')!.toBoolValue()!,
      );
    }).toList();
  }
}

extension on EnumElement {
  FieldElement? get enumValueProperty {
    final annotatedProperties = fields
        .where((e) => !e.isEnumConstant)
        .where(_enumPropertyChecker.hasAnnotationOfExact)
        .toList();
    if (annotatedProperties.length > 1) {
      _err('Only one property can be annotated with @enumProperty', this);
    } else {
      return annotatedProperties.firstOrNull;
    }
  }
}

extension on Element {
  String get isarName {
    final ann = _nameChecker.firstAnnotationOfExact(nonSynthetic);
    late String name;
    if (ann == null) {
      name = this.name!;
    } else {
      name = ann.getField('name')!.toStringValue()!;
    }
    _checkIsarName(name, this);
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
      ignore: ann
          .getField('ignore')!
          .toSetValue()!
          .map((e) => e.toStringValue()!)
          .toSet(),
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

  Embedded? get embeddedAnnotation {
    final ann = _embeddedChecker.firstAnnotationOfExact(nonSynthetic);
    if (ann == null) {
      return null;
    }
    return Embedded(
      inheritance: ann.getField('inheritance')!.toBoolValue()!,
      ignore: ann
          .getField('ignore')!
          .toSetValue()!
          .map((e) => e.toStringValue()!)
          .toSet(),
    );
  }
}

void _checkIsarName(String name, Element element) {
  if (name.isEmpty || name.startsWith('_')) {
    _err('Names must not be blank or start with "_".', element);
  }
}

Never _err(String msg, [Element? element]) {
  throw InvalidGenerationSourceError(msg, element: element);
}

extension on String {
  String capitalize() {
    switch (length) {
      case 0:
        return this;
      case 1:
        return toUpperCase();
      default:
        return substring(0, 1).toUpperCase() + substring(1);
    }
  }

  String decapitalize() {
    switch (length) {
      case 0:
        return this;
      case 1:
        return toLowerCase();
      default:
        return substring(0, 1).toLowerCase() + substring(1);
    }
  }
}
