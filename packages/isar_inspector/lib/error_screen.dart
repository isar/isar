// ignore: avoid_web_libraries_in_flutter
import 'dart:html';

import 'package:flutter/material.dart';

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Disconnected',
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 10),
          const Text('Please make sure your Isar instance is running.'),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: window.location.reload,
            child: const Text('Retry Connection'),
          ),
        ],
      ),
    );
  }
}
