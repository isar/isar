import 'package:isar_test/isar_test_context.dart';

import 'filters/bool_filter_test.dart' as bool_filter;
import 'filters/double_filter_test.dart' as double_filter;
import 'filters/float_filter_test.dart' as float_filter;
import 'filters/int_filter_test.dart' as int_filter;
import 'filters/link_filter_test.dart' as link_filter;
import 'filters/long_filter_test.dart' as long_filter;
import 'filters/string_filter_test.dart' as string_filter;

import 'converter_test.dart' as converter_test;
import 'crud_test.dart' as crud_test;
import 'group_test.dart' as group_test;
import 'link_test.dart' as link_test;
import 'watcher_test.dart' as watcher_test;

void run(IsarTestContext context) {
  bool_filter.run(context);
  double_filter.run(context);
  float_filter.run(context);
  int_filter.run(context);
  link_filter.run(context);
  long_filter.run(context);
  string_filter.run(context);

  converter_test.run(context);
  crud_test.run(context);
  group_test.run(context);
  link_test.run(context);
  watcher_test.run(context);
}
