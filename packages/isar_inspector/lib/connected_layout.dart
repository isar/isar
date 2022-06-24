import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:isar_inspector/filter_field.dart';
import 'package:isar_inspector/query_table.dart';
import 'package:isar_inspector/sidebar.dart';
import 'package:isar_inspector/state/instances_state.dart';
import 'package:isar_inspector/state/isar_connect_state_notifier.dart';

class ConnectedLayout extends ConsumerStatefulWidget {
  const ConnectedLayout({super.key});

  @override
  ConsumerState<ConnectedLayout> createState() => _ConnectedLayoutState();
}

class _ConnectedLayoutState extends ConsumerState<ConnectedLayout> {
  @override
  void initState() {
    final instance = ref.read(selectedInstancePod).value!;
    ref.read(isarConnectPod.notifier).watchInstance(instance);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(
            width: 300,
            child: Sidebar(),
          ),
          const SizedBox(width: 25),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                FilterField(),
                SizedBox(height: 25),
                Expanded(
                  child: QueryTable(),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
