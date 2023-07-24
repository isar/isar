import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pub_app/provider.dart';
import 'package:pub_app/ui/publisher.dart';
import 'package:pub_app/ui/search.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  static bool refreshed = false;

  @override
  void initState() {
    super.initState();

    if (!refreshed) {
      ref
          .read(packageManagerPod.future)
          .then((pm) => pm.bulkLoad('is:flutter-favorite'));
      refreshed = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 230,
                child: Search(
                  onSearch: (query) {
                    context.go('/search/$query');
                  },
                ),
              ),
              const Favorites(),
            ],
          ),
        ),
      ),
    );
  }
}

final randomFavoriteNamesPod = StreamProvider((ref) async* {
  final manager = await ref.watch(packageManagerPod.future);
  Set<String>? previousNames;
  await for (final packageNames in manager.watchFavoriteNames()) {
    if (packageNames.isNotEmpty &&
        (previousNames == null ||
            !setEquals(packageNames.toSet(), previousNames))) {
      previousNames = packageNames.toSet();
      packageNames.shuffle();
      yield packageNames.take(10).toList();
    }
  }
});

class Favorites extends ConsumerWidget {
  const Favorites({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final favoriteNames = ref.watch(randomFavoriteNamesPod).valueOrNull;

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Flutter Favorites',
            style: theme.textTheme.displaySmall!.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            'Some of the packages that demonstrate the highest levels '
            'of quality, selected by the Flutter Ecosystem Committee',
            style: theme.textTheme.titleMedium,
          ),
          if (favoriteNames != null) ...[
            const SizedBox(height: 15),
            for (final name in favoriteNames)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: PackageCard(name: name),
              ),
          ],
        ],
      ),
    );
  }
}

class PackageCard extends ConsumerWidget {
  const PackageCard({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final package = ref.watch(packagePod(PackageNameVersion(name))).valueOrNull;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push('/packages/$name');
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.headlineSmall!.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                if (package?.description != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    package!.description!.trim(),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
                if (package?.publisher != null) ...[
                  const SizedBox(height: 5),
                  Publisher(package!.publisher!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
