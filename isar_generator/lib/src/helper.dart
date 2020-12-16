import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';
import 'package:isar_annotation/isar_annotation.dart';

final _ignoreChecker = const TypeChecker.fromRuntime(Ignore);
final _nameChecker = const TypeChecker.fromRuntime(Name);
final _indexChecker = const TypeChecker.fromRuntime(Index);

bool hasIgnoreAnn(Element element) {
  return _ignoreChecker.hasAnnotationOfExact(element);
}

Name getNameAnn(Element element) {
  var ann = _nameChecker.firstAnnotationOfExact(element);
  if (ann == null) return null;
  return Name(ann.getField('name').toStringValue());
}

List<Index> getIndexAnns(Element element) {
  return _indexChecker.annotationsOfExact(element).map((ann) {
    var rawComposite = ann.getField('composite').toListValue();
    List<String> composite;
    if (rawComposite != null) {
      composite = rawComposite.map((e) => e.toStringValue()).toList();
    }
    return Index(
      composite: composite ?? [],
      unique: ann.getField('unique').toBoolValue(),
      hashValue: ann.getField('hashValue').toBoolValue(),
    );
  }).toList();
}

void err(String msg, [Element element]) {
  throw InvalidGenerationSourceError(msg, element: element);
}
