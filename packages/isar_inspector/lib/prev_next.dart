import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_inspector/common.dart';
import 'package:isar_inspector/state/query_state.dart';

class PrevNext extends ConsumerWidget {
  const PrevNext({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offset = ref.watch(queryOffsetPod);
    final result = ref.watch(queryResultsPod).valueOrNull;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Button(
          label: 'Prev',
          onPressed: offset > 0
              ? () {
                  ref.read(queryOffsetPod.state).state -= objectsPerPage;
                }
              : null,
        ),
        const SizedBox(width: 20),
        _Button(
          label: 'Next',
          onPressed: result?.hasMore ?? false
              ? () {
                  ref.read(queryOffsetPod.state).state += objectsPerPage;
                }
              : null,
        ),
      ],
    );
  }
}

class _Button extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _Button({
    Key? key,
    required this.label,
    this.onPressed,
  }) : super(key: key);

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
            color: onPressed != null ? theme.primaryColor : null,
          ),
        ),
      ),
    );
  }
}
