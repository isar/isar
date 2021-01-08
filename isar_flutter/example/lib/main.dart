//@dart=2.8

import 'package:example/isar.g.dart';
import 'package:example/user.dart';
import 'package:flutter/material.dart';

void main() async {
  final isar = await openIsar();
  await isar.writeTxn((isar) async {
    final user = User()
      ..name = "Hello"
      ..age = 5;
    await isar.users.put(user);
    print(user.createdAt);
  });
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Center(child: Text('Flutter Demo Home Page')),
    );
  }
}
