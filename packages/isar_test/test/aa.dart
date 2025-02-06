import 'dart:js_interop';

import 'package:isar_test/src/common.dart';
import 'package:web/web.dart';

import 'name_test.dart';

void main() async {
  Worker('http://localhost:3000/worker.js'.toJS);
}
