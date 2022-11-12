import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:pub_app/main.dart';
import 'package:url_launcher/url_launcher.dart';

class PubAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const PubAppBar({super.key, this.favorite = false});

  final bool favorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(darkModePod);
    return AppBar(
      automaticallyImplyLeading: false,
      title: GestureDetector(
        onTap: () {
          context.go('/');
        },
        child: AnimatedCrossFade(
          firstChild: SvgPicture.asset('assets/pub_logo_dark.svg', width: 150),
          secondChild: SvgPicture.asset('assets/pub_logo.svg', width: 150),
          crossFadeState:
              darkMode ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: kThemeChangeDuration,
        ),
      ),
      centerTitle: false,
      actions: [
        if (favorite)
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                launchUrl(
                  Uri.parse(
                    'https://docs.flutter.dev/development/packages-and-plugins/favorites',
                  ),
                );
              },
              icon: const FlutterLogo(),
              label: const Text('Flutter Favorite'),
            ),
          ),
        IconButton(
          icon: Icon(
            darkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          ),
          onPressed: () {
            ref.read(darkModePod.notifier).state = !darkMode;
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => AppBar().preferredSize;
}
