import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar_inspector/colored_page.dart';
import 'package:isar_inspector/common.dart';
import 'package:isar_inspector/connection_screen.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _textController = TextEditingController();
  final urlRE = RegExp(r'^https:\/\/inspect\.isar\.dev\/#\/(\d+)\/([\w-]+)$');
  String? _port;
  String? _secret;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'Isar Inspector',
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.transparent,
          primaryColor: Colors.blue,
          cardColor: const Color(0xff1f2128),
          dividerColor: Colors.grey,
          checkboxTheme: CheckboxThemeData(
            fillColor: MaterialStateProperty.all(Colors.blue),
          ),
          popupMenuTheme: const PopupMenuThemeData(
            color: Color.fromARGB(255, 40, 41, 46),
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
        home: ColoredPage(
          child: _port != null
              ? ConnectionScreen(
                  port: _port!,
                  secret: _secret!,
                )
              : Center(
                  child: IsarCard(
                    radius: BorderRadius.circular(20),
                    child: Container(
                      width: 600,
                      height: 200,
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextField(
                            controller: _textController,
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: Colors.white,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              contentPadding: const EdgeInsets.all(20),
                              errorText: _error,
                              labelText: 'Enter URL',
                            ),
                            onSubmitted: (_) => _connect(),
                            style: GoogleFonts.sourceCodePro(),
                          ),
                          ElevatedButton(
                            onPressed: _connect,
                            child: const Text('Connect'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  void _connect() {
    final url = _textController.text.trim();
    if (!urlRE.hasMatch(url)) {
      setState(() {
        _error = 'Invalid Url';
      });
      return;
    }

    final match = urlRE.firstMatch(url)!;

    setState(() {
      _port = match.group(1);
      _secret = match.group(2);
      _error = null;
    });
  }
}
