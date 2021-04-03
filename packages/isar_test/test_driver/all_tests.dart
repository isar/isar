import '../test/filters/bool_filter_test.dart' as bool_filter;
import '../test/filters/double_filter_test.dart' as double_filter;
import '../test/filters/float_filter_test.dart' as float_filter;
import '../test/filters/int_filter_test.dart' as int_filter;
import '../test/filters/link_filter_test.dart' as link_filter;
import '../test/filters/long_filter_test.dart' as long_filter;
import '../test/filters/string_filter_test.dart' as string_filter;

import '../test/offset_limit_test.dart' as offset_limit_test;
import '../test/converter_test.dart' as converter_test;
import '../test/crud_test.dart' as crud_test;
import '../test/group_test.dart' as group_test;
import '../test/link_test.dart' as link_test;
import '../test/property_query_test.dart' as qroperty_query_test;
import '../test/watcher_test.dart' as watcher_test;

void run() {
  bool_filter.main();
  double_filter.main();
  float_filter.main();
  int_filter.main();
  link_filter.main();
  long_filter.main();
  string_filter.main();

  offset_limit_test.main();
  converter_test.main();
  crud_test.main();
  group_test.main();
  link_test.main();
  qroperty_query_test.main();
  qroperty_query_test.main();
  //watcher_test.main();
}
