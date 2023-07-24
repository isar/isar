import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pub_app/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class PackageVersions extends ConsumerWidget {
  const PackageVersions({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final versions = ref.watch(packageVersionsPod(name)).valueOrNull ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final version in versions) ...[
          InkWell(
            onTap: () {
              context.push(
                '/packages/$name/versions/${Uri.encodeComponent(version.version)}',
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Text(
                      version.version,
                      style: theme.textTheme.headlineSmall!.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    Text(timeago.format(version.published))
                  ],
                ),
              ),
            ),
          ),
          const Divider(),
        ]
      ],
    );
  }
}
