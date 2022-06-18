import 'package:flutter/material.dart';

class ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback retry;

  const ErrorScreen({
    Key? key,
    required this.message,
    required this.retry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: retry,
        child: Text(message),
      ),
    );
  }
}
