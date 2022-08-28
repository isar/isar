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

  /*final intListTestFile = File('test/filter/filter_int_list_test.dart');
  final intListTest = intListTestFile.readAsStringSync();
  final longListTest = intListTest
      .replaceAll('Int', 'Long')
      .replaceAll('short', 'int')
      .replaceAll('filter_int_test', 'filter_long_test')
      .replaceAll('intModels', 'longModels');
  File('test/filter/filter_long_list_test.dart')
      .writeAsStringSync(longListTest);*/

  final floatTestFile = File('test/filter/filter_float_test.dart');
  final floatTest = floatTestFile.readAsStringSync();
  final doubleTest = floatTest
      .replaceAll('Float', 'Double')
      .replaceAll('float', 'double')
      .replaceAll('filter_float_test', 'filter_double_test')
      .replaceAll('floatModels', 'doubleModels');
  File('test/filter/filter_double_test.dart').writeAsStringSync(doubleTest);

  final floatListTestFile = File('test/filter/filter_float_list_test.dart');
  final floatListTest = floatListTestFile.readAsStringSync();
  final doubleListTest = floatListTest
      .replaceAll('Float', 'Double')
      .replaceAll('float', 'double')
      .replaceAll('filter_float_test', 'filter_double_test')
      .replaceAll('floatModels', 'doubleModels');
  File('test/filter/filter_double_list_test.dart')
      .writeAsStringSync(doubleListTest);

// where clauses
  final whereIntTestFile = File('test/index/where_int_test.dart');
  final whereIntTest = whereIntTestFile.readAsStringSync();
  final whereLongTest = whereIntTest
      .replaceAll('Int', 'Long')
      .replaceAll('short', 'int')
      .replaceAll('where_int_test', 'where_long_test')
      .replaceAll('intModels', 'longModels');
  File('test/index/where_long_test.dart').writeAsStringSync(whereLongTest);

  /*final whereIntListTestFile = File('test/index/where_int_list_test.dart');
  final whereIntListTest = whereIntListTestFile.readAsStringSync();
  final whereLongListTest = whereIntListTest
      .replaceAll('Int', 'Long')
      .replaceAll('short', 'int')
      .replaceAll('where_int_test', 'where_long_test')
      .replaceAll('intModels', 'longModels');
  File('test/index/where_long_list_test.dart')
      .writeAsStringSync(whereLongListTest);*/

  final whereFloatTestFile = File('test/index/where_float_test.dart');
  final whereFloatTest = whereFloatTestFile.readAsStringSync();
  final whereDoubleTest = whereFloatTest
      .replaceAll('Float', 'Double')
      .replaceAll('float', 'double')
      .replaceAll('where_float_test', 'where_double_test')
      .replaceAll('floatModels', 'doubleModels');
  File('test/index/where_double_test.dart').writeAsStringSync(whereDoubleTest);

  final whereFloatListTestFile = File('test/index/where_float_list_test.dart');
  final whereFloatListTest = whereFloatListTestFile.readAsStringSync();
  final whereDoubleListTest = whereFloatListTest
      .replaceAll('Float', 'Double')
      .replaceAll('float', 'double')
      .replaceAll('where_float_test', 'where_double_test')
      .replaceAll('floatModels', 'doubleModels');
  File('test/index/where_double_list_test.dart')
      .writeAsStringSync(whereDoubleListTest);
}
