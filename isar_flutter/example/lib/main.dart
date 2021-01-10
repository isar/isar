//@dart=2.8

import 'package:example/isar.g.dart';
import 'package:example/user.dart';
import 'package:flutter/material.dart';

Isar isar;

void main() async {
  isar = await openIsar();
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
      home: Material(
        child: Center(
            child: InkWell(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Flutter Demo Home Page'),
              CircularProgressIndicator(),
            ],
          ),
          onTap: () async {
            final t = Stopwatch()..start();
            isar.writeTxnSync((isar) {
              for (var i = 0; i < 1000; i++) {
                final user = User()
                  ..name = "User"
                  ..age = 5;
                isar.users.putSync(user);
              }
            });
            print('TIME:' + t.elapsedMilliseconds.toString());
          },
        )),
      ),
    );
  }
}
