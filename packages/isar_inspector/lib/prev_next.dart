import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_inspector/common.dart';
import 'package:isar_inspector/state/query_state.dart';

class PrevNext extends ConsumerWidget {
  const PrevNext({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(queryPagePod);
    final result = ref.watch(queryResultsPod).valueOrNull;

    int from, to, total, pages = 1;
    if (result != null && result.count > 0) {
      from = (page - 1) * objectsPerPage + 1;
      to = from + objectsPerPage - 1;
      total = result.count;

      if (to > total) {
        to = total;
      }

      pages = (total / objectsPerPage).ceil();
    } else {
      from = to = total = 0;
    }

    return Stack(
      children: [
        Align(
          alignment: Alignment.bottomLeft,
          child: Text('Displaying objects $from - $to of $total'),
        ),
        Align(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Button(
                label: 'Prev',
                onPressed: page > 1
                    ? () => ref.read(queryPagePod.state).state -= 1
                    : null,
              ),
              const SizedBox(width: 10),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  icon: const Icon(Icons.arrow_drop_up),
                  value: page,
                  items: List.generate(
                    pages,
                    (page) => DropdownMenuItem(
                      value: page + 1,
                      child: Center(child: Text('Page ${page + 1}')),
                    ),
                  ),
                  onChanged: pages > 1
                      ? (p) {
                          if (p != null) {
                            ref.read(queryPagePod.state).state = p;
                          }
                        }
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              _Button(
                label: 'Next',
                onPressed: to == total
                    ? null
                    : () => ref.read(queryPagePod.state).state += 1,
              ),
            ],
          ),
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
