import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:isar_inspector/connection_screen.dart';

void main() async {
  runApp(const App());
}

final _router = GoRouter(
  routes: <GoRoute>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const Material(
          child: Center(
            child: Text(
              'Welcome to the Isar Inspector!\nPlease open the link '
              'displayed when running the debug version of an Isar app.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ),
        );
      },
    ),
    GoRoute(
      path: '/:port/:secret',
      builder: (BuildContext context, GoRouterState state) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: Material(
            child: ConnectionScreen(
              port: state.params['port']!,
              secret: state.params['secret']!,
            ),
          ),
        );
      },
    ),
  ],
);

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  var darkMode = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Isar Inspector',
      routeInformationProvider: _router.routeInformationProvider,
      routeInformationParser: _router.routeInformationParser,
      routerDelegate: _router.routerDelegate,
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9FC9FF),
          brightness: darkMode ? Brightness.dark : Brightness.light,
        ),
        useMaterial3: true,
      ),
    );
  }
}
