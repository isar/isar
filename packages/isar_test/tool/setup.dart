import 'generate_all_tests.dart' as generate_all;
import 'generate_long_double_test.dart' as generate_long_double;
import 'generate_prepare_test.dart' as generate_prepare;

void main() {
  generate_all.main();
  generate_long_double.main();
  generate_prepare.main();
}
