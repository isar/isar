import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pub_app/provider.dart';
import 'package:pub_app/ui/package_metadata.dart';
import 'package:pub_app/ui/search.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key, required this.query});

  final String query;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final controller = ScrollController();
  final List<String> packages = [];

  late String query = widget.query;
  bool loading = false;
  bool online = true;

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      if (controller.position.extentAfter < 500 && !loading) {
        _loadMore();
      }
    });
    _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 230,
            child: Search(
              query: widget.query,
              onSearch: (q) {
                setState(() {
                  query = q;
                  packages.clear();
                });
                _loadMore();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: ChoiceChip(
                label: Text(online ? 'Online' : 'Offline'),
                selected: online,
                onSelected: (value) {
                  setState(() {
                    online = value;
                    packages.clear();
                  });
                  _loadMore();
                },
              ),
            ),
          ),
          if (packages.isNotEmpty)
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemBuilder: (context, index) {
                  return SearchResult(name: packages[index]);
                },
                itemCount: packages.length,
              ),
            )
          else if (loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            const Expanded(child: Center(child: Text('No Results'))),
        ],
      ),
    );
  }

  Future<void> _loadMore() async {
    try {
      loading = true;
      final manager = await ref.read(packageManagerPod.future);
      final newPackages =
          await manager.search(query, packages.length ~/ 10, online: online);
      if (mounted) {
        setState(() {
          packages.addAll(newPackages);
        });
      }
    } finally {
      loading = false;
    }
  }
}

class SearchResult extends ConsumerWidget {
  const SearchResult({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final package =
        ref.watch(freshPackagePod(PackageNameVersion(name))).valueOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () {
            context.push('/packages/$name');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.titleLarge),
                if (package?.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    package!.description!,
                    style: theme.textTheme.bodyMedium!.copyWith(fontSize: 13),
                    maxLines: 4,
                  ),
                ],
                if (package != null) ...[
                  const SizedBox(height: 12),
                  Scores(
                    package: package,
                    alwaysShowLatest: true,
                  ),
                ],
                if (package?.platforms?.isEmpty == false ||
                    package?.flutter == true ||
                    package?.dart == true) ...[
                  const SizedBox(height: 12),
                  Platforms(package: package!, compact: true),
                ]
              ],
            ),
          ),
        ),
        const Divider(),
      ],
    );
  }
}
