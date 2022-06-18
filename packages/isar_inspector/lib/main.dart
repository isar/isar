import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_inspector/pages/connection_page.dart';
import 'package:isar_inspector/pages/home_page.dart';
import 'package:routemaster/routemaster.dart';

import 'pages/base_page.dart';

void main() async {
  runApp(ProviderScope(
    child: MaterialApp.router(
      title: 'Isar Inspector',
      routerDelegate: RoutemasterDelegate(
        routesBuilder: (context) => RouteMap(
          routes: {
            '/': (_) => const MaterialPage(child: BasePage(HomePage())),
            '/:port/:secret': (data) => MaterialPage(
                  child: BasePage(ConnectionPage(
                    port: data.pathParameters['port'] ?? '',
                    secret: data.pathParameters['secret'] ?? '',
                  )),
                ),
          },
        ),
      ),
      routeInformationParser: const RoutemasterParser(),
    ),
  ));
}
