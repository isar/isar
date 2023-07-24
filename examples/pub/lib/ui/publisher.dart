import 'package:flutter/material.dart';

class Publisher extends StatelessWidget {
  const Publisher(this.publisher, {super.key});

  final String publisher;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.verified_outlined,
          size: 16,
        ),
        const SizedBox(width: 2),
        Text(
          publisher,
          style: theme.textTheme.titleSmall!
              .copyWith(color: theme.colorScheme.primary),
        ),
      ],
    );
  }
}
