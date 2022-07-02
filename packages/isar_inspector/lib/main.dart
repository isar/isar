import 'package:flutter/material.dart';

import 'package:isar_inspector/app_io.dart'
    if (dart.library.html) 'package:isar_inspector/app_web.dart';

void main() async {
  //ignore: prefer_const_constructors
  runApp(App());
}
