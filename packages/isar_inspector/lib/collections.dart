import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_inspector/common.dart';
import 'package:isar_inspector/state/collections_state.dart';

class CollectionsList extends ConsumerWidget {
  const CollectionsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final collections = ref.watch(collectionsPod).valueOrNull ?? [];
    final collectionInfo = ref.watch(collectionInfoPod);
    final selectedCollection = ref.watch(selectedCollectionPod).valueOrNull;

    return ListView.builder(
      itemBuilder: (BuildContext context, int index) {
        final collection = collections.elementAt(index);
        final info = collectionInfo[collection.name];
        return SizedBox(
          height: 55,
          child: IsarCard(
            color: collection == selectedCollection ? theme.primaryColor : null,
            radius: BorderRadius.circular(60),
            onTap: () {
              ref.read(selectedCollectionNamePod.state).state = collection.name;
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                children: [
                  Text(
                    collection.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  if (info != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          info.count.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatSize(info.size),
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
      itemCount: collections.length,
    );
  }
}

String _formatSize(int bytes) {
  if (bytes < 10000) {
    return '${bytes.toStringAsFixed(2)}B';
  } else if (bytes < 1000000) {
    return '${(bytes / 1000).toStringAsFixed(2)}KB';
  } else if (bytes < 1000000000) {
    return '${(bytes / 1000000).toStringAsFixed(2)}MB';
  } else {
    return '${(bytes / 1000000000).toStringAsFixed(2)}GB';
  }
}
