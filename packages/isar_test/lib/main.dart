import 'package:flutter/material.dart';

/// Minimal main entry point for integration testing.
/// This app is not meant to be used directly - it's a test framework.
void main() {
  runApp(const IsarTestApp());
}

class IsarTestApp extends StatelessWidget {
  const IsarTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Isar Test Framework',
      home: Scaffold(
        body: Center(
          child: Text(
            'Isar Test Framework\n\nThis is not a user app.\nRun integration tests instead.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
