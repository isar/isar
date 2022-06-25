import 'package:flutter/material.dart';

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({
    super.key,
    required this.message,
    required this.retry,
  });
  final String message;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 10),
          const Text(
            'Please make sure your Isar instance is '
            'running and you use the Chrome browser.',
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: retry,
            child: const Text('Retry Connection'),
          ),
        ],
      ),
    );
  }
}
