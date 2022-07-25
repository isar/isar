import 'package:dartx/dartx.dart';

String generateLength(
  String objectName,
  String propertyName,
  String Function(
    String lower,
    String includeLower,
    String upper,
    String includeUpper,
  )
      codeGen,
) {
  return '''
      QueryBuilder<$objectName, $objectName, QAfterFilterCondition> ${propertyName.decapitalize()}LengthEqualTo(int length) {
        return ${codeGen('length', 'true', 'length', 'true')};
      }

      QueryBuilder<$objectName, $objectName, QAfterFilterCondition> ${propertyName.decapitalize()}IsEmpty() {
        return ${codeGen('0', 'true', '0', 'true')};
      }

      QueryBuilder<$objectName, $objectName, QAfterFilterCondition> ${propertyName.decapitalize()}IsNotEmpty() {
        return ${codeGen('0', 'false', '999999', 'true')};
      }

      QueryBuilder<$objectName, $objectName, QAfterFilterCondition> ${propertyName.decapitalize()}LengthLessThan(
        int length, {
        bool include = false,
      }) {
        return ${codeGen('0', 'true', 'length', 'include')};
      }

      QueryBuilder<$objectName, $objectName, QAfterFilterCondition> ${propertyName.decapitalize()}LengthGreaterThan(
        int length, {
        bool include = false,
      }) {
        return ${codeGen('length', 'include', '999999', 'true')};
      }

      QueryBuilder<$objectName, $objectName, QAfterFilterCondition> ${propertyName.decapitalize()}LengthBetween(
        int lower, 
        int upper, {
        bool includeLower = true,
        bool includeUpper = true,
      }) {
        return ${codeGen('lower', 'includeLower', 'upper', 'includeUpper')};
      }
      ''';
}
