import '../test/constructor_test.dart' as constructor_test;
import '../test/converter_test.dart' as converter_test;
import '../test/crud_test.dart' as crud_test;

import '../test/filter_bool_test.dart' as bool_filter_test;
import '../test/filter_double_test.dart' as double_filter_test;
import '../test/filter_float_test.dart' as float_filter_test;
import '../test/filter_int_test.dart' as int_filter_test;
import '../test/filter_link_test.dart' as link_filter_test;
import '../test/filter_long_test.dart' as long_filter_test;
import '../test/filter_string_test.dart' as string_filter_test;

import '../test/index_test.dart' as index_test;
import '../test/index_composite_test.dart' as index_composite_test;
import '../test/index_get_by_delete_by_test.dart'
    as index_get_by_delete_by_test;
import '../test/index_multi_entry_test.dart' as index_multi_entry_test;

import '../test/json_test.dart' as json_test;
import '../test/link_test.dart' as link_test;
import '../test/name_test.dart' as name_test;
import '../test/other_test.dart' as other_test;

import '../test/query_aggregation_test.dart' as query_aggregation_test;
import '../test/query_group_test.dart' as query_group_test;
import '../test/query_offset_limit_test.dart' as query_offset_limit_test;
import '../test/query_property_test.dart' as query_property_test;
import '../test/query_sort_by_distinct_by_test.dart' as query_sort_by_test;
import '../test/query_where_sort_distinct_test.dart'
    as query_where_sort_distinct;

import '../test/schema_test.dart' as schema_test;
import '../test/watcher_test.dart' as watcher_tests;

void run() {
  constructor_test.main();
  converter_test.main();
  crud_test.main();

  bool_filter_test.main();
  double_filter_test.main();
  float_filter_test.main();
  int_filter_test.main();
  link_filter_test.main();
  long_filter_test.main();
  string_filter_test.main();

  index_test.main();
  index_composite_test.main();
  index_get_by_delete_by_test.main();
  index_multi_entry_test.main();

  json_test.main();
  link_test.main();
  name_test.main();
  other_test.main();

  query_aggregation_test.main();
  query_group_test.main();
  query_offset_limit_test.main();
  query_property_test.main();
  query_sort_by_test.main();
  query_where_sort_distinct.main();

  schema_test.main();
  watcher_tests.main();
}
