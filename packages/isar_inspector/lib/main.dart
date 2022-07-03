import 'package:flutter/material.dart';

import 'package:isar_inspector/desktop/app.dart'
    if (dart.library.html) 'package:isar_inspector/web/app.dart';

void main() async {
  //ignore: prefer_const_constructors
  runApp(App());
}
