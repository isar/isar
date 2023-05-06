import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:isar/isar.dart';
import 'package:source_gen/source_gen.dart';

const TypeChecker _collectionChecker = TypeChecker.fromRuntime(Collection);
const TypeChecker _enumeratedChecker = TypeChecker.fromRuntime(Enumerated);
const TypeChecker _embeddedChecker = TypeChecker.fromRuntime(Embedded);
const TypeChecker _idChecker = TypeChecker.fromRuntime(Id);
const TypeChecker _ignoreChecker = TypeChecker.fromRuntime(Ignore);
const TypeChecker _nameChecker = TypeChecker.fromRuntime(Name);

extension ClassElementX on ClassElement {
  List<PropertyInducingElement> get allAccessors {
    final ignoreFields =
        collectionAnnotation?.ignore ?? embeddedAnnotation!.ignore;
    final allAccessors = [
      ...accessors.map((e) => e.variable),
      if (collectionAnnotation?.inheritance ?? embeddedAnnotation!.inheritance)
        for (InterfaceType supertype in allSupertypes) ...[
          if (!supertype.isDartCoreObject)
            ...supertype.accessors.map((e) => e.variable)
        ]
    ];

    final usableAccessors = allAccessors.where(
      (e) =>
          e.isPublic &&
          !e.isStatic &&
          !_ignoreChecker.hasAnnotationOf(e.nonSynthetic) &&
          !ignoreFields.contains(e.name),
    );

    final uniqueAccessors = <String, PropertyInducingElement>{};
    for (final accessor in usableAccessors) {
      uniqueAccessors[accessor.name] = accessor;
    }
    return uniqueAccessors.values.toList();
  }

  List<String> get enumConsts {
    return fields.where((e) => e.isEnumConstant).map((e) => e.name).toList();
  }
}

extension PropertyElementX on PropertyInducingElement {
  Enumerated? get enumeratedAnnotation {
    final ann = _enumeratedChecker.firstAnnotationOfExact(nonSynthetic);
    if (ann == null) {
      return null;
    }
    final typeIndex = ann.getField('type')!.getField('index')!.toIntValue()!;
    return Enumerated(
      EnumType.values[typeIndex],
      ann.getField('property')?.toStringValue(),
    );
  }

  bool get hasIdAnnotation {
    final ann = _idChecker.firstAnnotationOfExact(nonSynthetic);
    return ann != null;
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

void checkIsarName(String name, Element element) {
  if (name.isEmpty || name.startsWith('_')) {
    err('Names must not be blank or start with "_".', element);
  }
}

Never err(String msg, [Element? element]) {
  throw InvalidGenerationSourceError(msg, element: element);
}

extension StringX on String {
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
