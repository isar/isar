import 'dart:io';

void main() {
  final intTestFile = File('test/filter/filter_int_test.dart');
  final intTest = intTestFile.readAsStringSync();

  final longTest = intTest
      .replaceAll('Int', 'Long')
      .replaceAll('short', 'int')
      .replaceAll('filter_int_test', 'filter_long_test')
      .replaceAll('intModels', 'longModels');
  File('test/filter/filter_long_test.dart').writeAsStringSync(longTest);

  final floatTestFile = File('test/filter/filter_float_test.dart');
  final floatTest = floatTestFile.readAsStringSync();

  final doubleTest = floatTest
      .replaceAll('Float', 'Double')
      .replaceAll('float', 'double')
      .replaceAll('filter_float_test', 'filter_double_test')
      .replaceAll('floatModels', 'doubleModels');
  File('test/filter/filter_double_test.dart').writeAsStringSync(doubleTest);
}
