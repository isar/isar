import 'dart:io';

void main() {
  final intTestFile = File('test/filter_int_test.dart');
  final intTest = intTestFile.readAsStringSync();

  final longTest = intTest
      .replaceAll('Int', 'Long')
      .replaceAll('@Size32()', '')
      .replaceAll('filter_int_test', 'filter_long_test')
      .replaceAll('intModels', 'longModels');
  File('test/filter_long_test.dart').writeAsStringSync(longTest);

  final floatTestFile = File('test/filter_float_test.dart');
  final floatTest = floatTestFile.readAsStringSync();

  final doubleTest = floatTest
      .replaceAll('Float', 'Double')
      .replaceAll('@Size32()', '')
      .replaceAll('filter_float_test', 'filter_double_test')
      .replaceAll('floatModels', 'doubleModels');
  File('test/filter_double_test.dart').writeAsStringSync(doubleTest);
}
