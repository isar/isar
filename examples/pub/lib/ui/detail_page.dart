import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pub_app/models/asset.dart';
import 'package:pub_app/models/package.dart';
import 'package:pub_app/provider.dart';
import 'package:pub_app/ui/app_bar.dart';
import 'package:pub_app/ui/markdown_viewer.dart';
import 'package:pub_app/ui/package_metadata.dart';
import 'package:pub_app/ui/package_versions.dart';

class DetailPage extends ConsumerWidget {
  const DetailPage({
    super.key,
    required this.name,
    this.version,
  });

  final String name;
  final String? version;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final package =
        ref.watch(freshPackagePod(PackageNameVersion(name, version)));
    return Scaffold(
      appBar: PubAppBar(
        favorite: package.valueOrNull?.flutterFavorite ?? false,
      ),
      body: SingleChildScrollView(
        child: package.map(
          data: (data) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: PackageHeader(package: data.value),
                ),
                const SizedBox(height: 20),
                PackageBody(package: data.value),
              ],
            );
          },
          error: (err) {
            return Center(child: Text('Error: $err'));
          },
          loading: (loading) => const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}

class PackageBody extends StatefulWidget {
  const PackageBody({super.key, required this.package});

  final Package package;

  @override
  State<PackageBody> createState() => _PackageBodyState();
}

class _PackageBodyState extends State<PackageBody> {
  _BodyPage page = _BodyPage.readme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MediaQuery.removePadding(
          removeBottom: true,
          context: context,
          child: NavigationBar(
            height: 60,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            selectedIndex: page.index,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.description_rounded),
                label: 'Readme',
              ),
              NavigationDestination(
                icon: Icon(Icons.change_history_rounded),
                label: 'Changelog',
              ),
              /*NavigationDestination(
                icon: Icon(Icons.adjust),
                label: 'Example',
              ),*/
              NavigationDestination(
                icon: Icon(Icons.list_alt_rounded),
                label: 'Versions',
              ),
            ],
            onDestinationSelected: (value) {
              setState(() {
                page = _BodyPage.values[value];
              });
            },
          ),
        ),
        const SizedBox(height: 20),
        if (page == _BodyPage.readme)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: PackageAsset(
              name: widget.package.name,
              version: widget.package.version,
              kind: AssetKind.readme,
            ),
          )
        else if (page == _BodyPage.changelog)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: PackageAsset(
              name: widget.package.name,
              version: widget.package.version,
              kind: AssetKind.changelog,
            ),
          )
        else if (page == _BodyPage.versions)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: PackageVersions(name: widget.package.name),
          ),
      ],
    );
  }
}

enum _BodyPage {
  readme,
  changelog,
  //example,
  versions;
}

class PackageAsset extends ConsumerWidget {
  const PackageAsset({
    super.key,
    required this.name,
    required this.version,
    required this.kind,
  });

  final String name;
  final String version;
  final AssetKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(assetsPod(PackageNameVersion(name, version)));
    return assets.map(
      data: (data) {
        final md = data.value[kind];
        if (md != null) {
          return MarkdownViewer(markdown: md);
        } else {
          return const Center(
            child: Text('This file is empty.'),
          );
        }
      },
      error: (err) => Center(child: Text('Error: $err')),
      loading: (loading) => const Center(child: CircularProgressIndicator()),
    );
  }
}
