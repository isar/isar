import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';
import 'package:isar/isar.dart';

final _collectionChecker = const TypeChecker.fromRuntime(Collection);
final _ignoreChecker = const TypeChecker.fromRuntime(Ignore);
final _nameChecker = const TypeChecker.fromRuntime(Name);
final _indexChecker = const TypeChecker.fromRuntime(Index);
final _size32Checker = const TypeChecker.fromRuntime(Size32);
final _oidKeyChecker = const TypeChecker.fromRuntime(Id);
final _backlinkChecker = const TypeChecker.fromRuntime(Backlink);
final _typeConverterChecker = const TypeChecker.fromRuntime(TypeConverter);
final _dateTimeChecker = const TypeChecker.fromRuntime(DateTime);
final _uint8ListChecker = const TypeChecker.fromRuntime(Uint8List);

bool hasIgnoreAnn(Element element) {
  return _ignoreChecker.hasAnnotationOfExact(element.nonSynthetic);
}

bool hasSize32Ann(Element element) {
  return _size32Checker.hasAnnotationOfExact(element.nonSynthetic);
}

bool hasIdAnn(Element element) {
  return _oidKeyChecker.hasAnnotationOfExact(element.nonSynthetic);
}

Collection? getCollectionAnn(Element element) {
  var ann = _collectionChecker.firstAnnotationOfExact(element.nonSynthetic);
  if (ann == null) return null;
  return Collection(
    inheritance: ann.getField('inheritance')!.toBoolValue()!,
    accessor: ann.getField('accessor')!.toStringValue(),
  );
}

Name? getNameAnn(Element element) {
  var ann = _nameChecker.firstAnnotationOfExact(element.nonSynthetic);
  if (ann == null) return null;
  return Name(ann.getField('name')!.toStringValue()!);
}

List<DartObject> getTypeConverterAnns(Element element) {
  final anns = _typeConverterChecker.annotationsOf(element.nonSynthetic);
  for (var ann in anns) {
    final reviver = ConstantReader(ann).revive();
    if (reviver.namedArguments.isNotEmpty ||
        reviver.positionalArguments.isNotEmpty) {
      err(
        'TypeConverters with constructor arguments are not supported.',
        ann.type!.element,
      );
    }
  }
  return anns.toList();
}

bool hasZeroArgsConstructor(ClassElement element) {
  return element.constructors
      .any((c) => c.isPublic && !c.parameters.any((p) => !p.isOptional));
}

List<Index> getIndexAnns(Element element) {
  return _indexChecker.annotationsOfExact(element.nonSynthetic).map((ann) {
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
      composite: composite,
      unique: ann.getField('unique')!.toBoolValue()!,
      type: indexType,
      caseSensitive: ann.getField('caseSensitive')!.toBoolValue(),
    );
  }).toList();
}

bool isDateTime(Element element) => _dateTimeChecker.isExactly(element);

bool isUint8List(Element element) => _uint8ListChecker.isExactly(element);

Backlink? getBacklinkAnn(Element element) {
  var ann = _backlinkChecker.firstAnnotationOfExact(element.nonSynthetic);
  if (ann == null) return null;
  return Backlink(to: ann.getField('to')!.toStringValue()!);
}

void err(String msg, [Element? element]) {
  throw InvalidGenerationSourceError(msg, element: element);
}
