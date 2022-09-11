// ignore_for_file: invalid_use_of_visible_for_testing_member, implementation_imports, avoid_web_libraries_in_flutter

import 'dart:js' as js;

import 'package:isar/src/web/open.dart' as isar_web;
import 'package:isar_test/src/isar_web_src.dart';

Future<void> init() async {
  js.context.callMethod('eval', [isarWebSrc]);
  isar_web.doNotInitializeIsarWeb();
}
