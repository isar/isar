import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:isar_inspector/colored_page.dart';
import 'package:isar_inspector/connection_screen.dart';

class App extends StatelessWidget {
  App({super.key});

  final _router = GoRouter(
    routes: <GoRoute>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const ColoredPage(
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
            child: ColoredPage(
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

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        title: 'Isar Inspector',
        routeInformationProvider: _router.routeInformationProvider,
        routeInformationParser: _router.routeInformationParser,
        routerDelegate: _router.routerDelegate,
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.transparent,
          primaryColor: Colors.blue,
          cardColor: const Color(0xff1f2128),
          // Color.fromARGB(255, 40, 41, 46),
          dividerColor: const Color.fromARGB(255, 40, 41, 46),
          checkboxTheme: CheckboxThemeData(
            fillColor: MaterialStateProperty.all(Colors.blue),
          ),
          buttonTheme: const ButtonThemeData(
            alignedDropdown: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ButtonStyle(
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              minimumSize: MaterialStateProperty.all(const Size(100, 50)),
            ),
          ),
          colorScheme: ColorScheme.fromSwatch().copyWith(
            secondary: Colors.blue,
            brightness: Brightness.dark,
          ),
          scrollbarTheme: ScrollbarThemeData(
            thumbColor: MaterialStateProperty.all(Colors.grey),
          ),
        ),
      ),
    );
  }
}
