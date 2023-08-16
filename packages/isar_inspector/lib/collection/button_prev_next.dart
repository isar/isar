import 'package:flutter/material.dart';
import 'package:isar_inspector/collection/collection_area.dart';

class PrevNextButtons extends StatelessWidget {
  const PrevNextButtons({
    required this.page,
    required this.count,
    required this.onChanged,
    super.key,
  });

  final int page;
  final int count;
  final void Function(int newPage) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    var from = 0;
    var to = 0;
    if (count > 0) {
      from = page * objectsPerPage + 1;
      to = from + objectsPerPage - 1;
      if (to > count) {
        to = count;
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Previous page',
          child: TextButton(
            onPressed: page > 0 ? () => onChanged(page - 1) : null,
            child: const Text('Prev'),
          ),
        ),
        const SizedBox(width: 10),
        Tooltip(
          message: 'Current page',
          child: Row(
            children: [
              Text(
                '$from',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                ' - ',
                style: TextStyle(
                  color: theme.colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
              Text(
                '$to',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Text(
          ' of ',
          style: TextStyle(
            color: theme.colorScheme.onBackground.withOpacity(0.7),
          ),
        ),
        Tooltip(
          message: 'Total number of objects',
          child: Text(
            '$count',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 10),
        Tooltip(
          message: 'Next page',
          child: TextButton(
            onPressed: to == count ? null : () => onChanged(page + 1),
            child: const Text('Next'),
          ),
        ),
      ],
    );
  }
}
