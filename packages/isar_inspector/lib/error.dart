import 'package:flutter/material.dart';
import 'package:isar_inspector/app_state.dart';
import 'package:isar_inspector/common.dart';
import 'package:provider/provider.dart';

class Error extends StatelessWidget {
  const Error({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Center(
      child: SizedBox(
        width: 350,
        child: IsarCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Something went wrong',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                Text(appState.error!),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    context.read<AppState>().updateObjects();
                  },
                  child: const Text(
                    'Try again',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
