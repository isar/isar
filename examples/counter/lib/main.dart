import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

part 'main.g.dart';

@collection
class Count {
  final int id;

  final int step;

  Count(this.id, this.step);
}

void main() async {
  await Isar.initialize();
  runApp(const CounterApp());
}

class CounterApp extends StatefulWidget {
  const CounterApp({super.key});

  @override
  State<CounterApp> createState() => _CounterAppState();
}

class _CounterAppState extends State<CounterApp> {
  late Isar _isar;

  @override
  void initState() {
    // Open Isar instance
    _isar = Isar.open(
      schemas: [CountSchema],
      directory: Isar.sqliteInMemory,
      engine: IsarEngine.sqlite,
    );
    super.initState();
  }

  void _incrementCounter() {
    // Persist counter value to database
    _isar.write((isar) async {
      isar.counts.put(
        Count(isar.counts.autoIncrement(), 1),
      );
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // This is just for demo purposes. You shouldn't perform database queries
    // in the build method.
    final count = _isar.counts.where().stepProperty().sum();
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
      useMaterial3: true,
    );
    return MaterialApp(
      title: 'Isar Counter',
      theme: theme,
      home: Scaffold(
        appBar: AppBar(title: const Text('Isar Counter')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'You have pushed the button this many times:',
              ),
              Text('$count', style: theme.textTheme.headlineMedium),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _incrementCounter,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
