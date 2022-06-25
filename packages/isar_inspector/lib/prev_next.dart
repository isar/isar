import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_inspector/common.dart';
import 'package:isar_inspector/state/query_state.dart';

class PrevNext extends ConsumerWidget {
  const PrevNext({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final page = ref.watch(queryPagePod);
    final result = ref.watch(queryResultsPod).valueOrNull;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Button(
              label: 'Prev',
              onPressed: () {
                if (page > 0) {
                  ref.read(queryPagePod.state).state -= 1;
                }
              },
            ),
            const SizedBox(width: 10),
            Text(
              'Page ${page + 1}',
              style: TextStyle(fontSize: 12, color: theme.hintColor),
            ),
            const SizedBox(width: 10),
            _Button(
              label: 'Next',
              onPressed: () {
                if (result?.hasMore ?? false) {
                  ref.read(queryPagePod.state).state += 1;
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    // ignore: unused_element
    super.key,
    required this.label,
    this.onPressed,
  });
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IsarCard(
      color: Colors.transparent,
      radius: BorderRadius.circular(15),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Text(
          label,
          style: TextStyle(
            color: onPressed != null ? theme.primaryColor : theme.hintColor,
          ),
        ),
      ),
    );
  }
}
