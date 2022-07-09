import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:isar_inspector/desktop/download.dart'
    if (dart.library.html) 'package:isar_inspector/web/download.dart';
import 'package:isar_inspector/query_builder.dart';
import 'package:isar_inspector/state/collections_state.dart';
import 'package:isar_inspector/state/instances_state.dart';
import 'package:isar_inspector/state/isar_connect_state_notifier.dart';
import 'package:isar_inspector/state/query_state.dart';

class FilterField extends ConsumerStatefulWidget {
  const FilterField({super.key});

  @override
  ConsumerState<FilterField> createState() => _FilterFieldState();
}

class _FilterFieldState extends ConsumerState<FilterField> {
  final TextEditingController controller = TextEditingController();
  String? error;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: () async {
            final selectedCollection = ref.read(selectedCollectionPod).value!;
            final filter = await showDialog<QueryBuilderUIGroupHelper?>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  content: QueryBuilderUI(
                    collection: selectedCollection,
                    filter: selectedCollection.lastFilter,
                  ),
                );
              },
            );

            if (filter != null) {
              selectedCollection.lastFilter = filter;
              ref.read(queryFilterPod.state).state =
                  QueryBuilderUI.parseQuery(filter);
              ref.read(queryPagePod.state).state = 1;
            }
          },
          child: const Text('Query Builder'),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: () async {
            final selectedCollection = ref.read(selectedCollectionPod).value!;
            final filter = selectedCollection.lastFilter == null
                ? null
                : QueryBuilderUI.parseQuery(selectedCollection.lastFilter!);
            final q = ConnectQuery(
              instance: ref.read(selectedInstancePod).value!,
              collection: selectedCollection.name,
              filter: filter,
            );

            final data = await ref.read(isarConnectPod.notifier).exportJson(q);
            await download(data, '${q.instance}_${q.collection}_query.json');
          },
          child: const Text('Download'),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: () {
            final selectedCollection = ref.read(selectedCollectionPod).value!;
            final filter = selectedCollection.lastFilter == null
                ? null
                : QueryBuilderUI.parseQuery(selectedCollection.lastFilter!);
            final query = ConnectQuery(
              instance: ref.read(selectedInstancePod).value!,
              collection: selectedCollection.name,
              filter: filter,
            );
            ref.read(isarConnectPod.notifier).removeQuery(query);
          },
          child: const Text('Remove'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
