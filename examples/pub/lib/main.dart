import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pub_app/ui/detail_page.dart';
import 'package:pub_app/ui/home_page.dart';
import 'package:pub_app/ui/search_page.dart';

void main() {
  runApp(ProviderScope(child: PubApp()));
}

final darkModePod = StateProvider((ref) => false);

class PubApp extends ConsumerWidget {
  PubApp({super.key});

  final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/packages/:package',
        builder: (context, state) => DetailPage(
          name: state.pathParameters['package']!,
        ),
      ),
      GoRoute(
        path: '/packages/:package/versions/:version',
        builder: (context, state) => DetailPage(
          name: state.pathParameters['package']!,
          version: state.pathParameters['version'],
        ),
      ),
      GoRoute(
        path: '/search/:query',
        builder: (context, state) => SearchPage(
          query: state.pathParameters['query']!,
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(darkModePod);
    return MaterialApp.router(
      routeInformationProvider: _router.routeInformationProvider,
      routeInformationParser: _router.routeInformationParser,
      routerDelegate: _router.routerDelegate,
      title: 'Pub',
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1c2834),
          brightness: darkMode ? Brightness.dark : Brightness.light,
        ),
        useMaterial3: true,
      ),
    );
  }
}
