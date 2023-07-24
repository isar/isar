import 'package:clickup_fading_scroll/clickup_fading_scroll.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pub_app/models/package.dart';
import 'package:pub_app/provider.dart';
import 'package:pub_app/ui/publisher.dart';
import 'package:timeago/timeago.dart' as timeago;

class PackageHeader extends ConsumerWidget {
  const PackageHeader({super.key, required this.package});

  final Package package;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Text(
          '${package.name} ${package.version}',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 3),
        Wrap(
          children: [
            Text(
              timeago.format(package.published),
              style: theme.textTheme.titleSmall,
            ),
            if (package.publisher != null) ...[
              Text(
                ' • ',
                style: theme.textTheme.titleSmall,
              ),
              Publisher(package.publisher!),
            ],
          ],
        ),
        const SizedBox(height: 15),
        Scores(package: package),
        const SizedBox(height: 15),
        Platforms(package: package),
        if (package.description != null) ...[
          const SizedBox(height: 15),
          Text(
            package.description!.trim(),
            style: theme.textTheme.bodyMedium!.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.9),
            ),
          ),
        ]
      ],
    );
  }
}

class Platforms extends StatelessWidget {
  const Platforms({super.key, required this.package, this.compact = false});

  final Package package;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final platforms = package.platforms?.map((e) => e.name).toList()?..sort();
    final sdks = [
      if (package.dart == true) 'DART',
      if (package.flutter == true) 'FLUTTER'
    ];
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: [
        if (sdks.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              sdks.join(' • '),
              style: theme.textTheme.titleSmall!.copyWith(
                fontSize: compact ? 9 : 11,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        if (platforms?.isEmpty == false)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              platforms!.join(' • ').toUpperCase(),
              style: theme.textTheme.titleSmall!.copyWith(
                fontSize: compact ? 9 : 11,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
      ],
    );
  }
}

class Scores extends ConsumerWidget {
  const Scores({
    super.key,
    required this.package,
    this.alwaysShowLatest = false,
  });

  final Package package;
  final bool alwaysShowLatest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestVersion = ref.watch(latestVersionPod(package.name)).valueOrNull;
    final preReleaseVersion =
        ref.watch(preReleaseVersionPod(package.name)).valueOrNull;

    final widgets = <Widget>[
      if (package.likes != null)
        ScoreItem(
          stat: package.likes.toString(),
          title: 'LIKES',
        ),
      if (package.points != null)
        ScoreItem(
          stat: package.points.toString(),
          title: 'PUB POINTS',
        ),
      if (package.popularity != null)
        ScoreItem(
          stat: '${(package.popularity! * 100).round()}%',
          title: 'POPULARITY',
        ),
      if (latestVersion != null &&
          (latestVersion != package.version || alwaysShowLatest))
        ScoreItem(
          stat: latestVersion,
          title: 'LATEST',
          onTap: () {
            context.push('/packages/${package.name}');
          },
        ),
      if (preReleaseVersion != null)
        ScoreItem(
          stat: preReleaseVersion,
          title: 'PRERELEASE',
          onTap: () {
            context
                .push('/packages/${package.name}/versions/$preReleaseVersion');
          },
        ),
    ];

    return FadingScroll(
      builder: (context, controller) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: controller,
          child: IntrinsicHeight(
            child: Row(
              //crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < widgets.length; i++) ...[
                  if (i != 0) const VerticalDivider(thickness: 1, width: 0),
                  widgets[i],
                ]
              ],
            ),
          ),
        );
      },
    );
  }
}

class ScoreItem extends StatelessWidget {
  const ScoreItem({
    super.key,
    required this.stat,
    required this.title,
    this.onTap,
  });

  final String stat;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stat,
              style: theme.textTheme.titleMedium!.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              title,
              style: theme.textTheme.labelSmall!.copyWith(
                fontSize: 9,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
