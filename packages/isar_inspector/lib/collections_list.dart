import 'dart:math';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:isar_inspector/connect_client.dart';

class CollectionsList extends StatelessWidget {
  const CollectionsList({
    required this.collections,
    required this.collectionInfo,
    required this.selectedCollection,
    required this.onSelected,
    super.key,
  });

  final List<IsarSchema> collections;
  final Map<String, ConnectCollectionInfoPayload?> collectionInfo;
  final String? selectedCollection;
  final void Function(String collection) onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      primary: false,
      itemBuilder: (BuildContext context, int index) {
        final collection = collections[index];
        final info = collectionInfo[collection.name];

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ElevatedButton(
            style: collection.name == selectedCollection
                ? ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                  )
                : null,
            onPressed: () {
              onSelected(collection.name);
            },
            child: Padding(
              padding: const EdgeInsets.only(
                left: 25,
                right: 10,
                top: 12,
                bottom: 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      collection.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        info?.count.toString() ?? 'loading',
                        style: const TextStyle(
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatSize(info?.size ?? 0),
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
  if (bytes <= 0) return '0 B';
  const suffixes = ['B', 'KB', 'MB', 'GB'];
  final n = (log(bytes) / log(1024)).floor();
  final index = min(n, suffixes.length - 1);
  final value = bytes / pow(1024, index);
  return '${value.toStringAsFixed(index == 0 ? 0 : 2)} ${suffixes[index]}';
}
