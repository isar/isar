import 'package:flutter/material.dart';

class BasePage extends StatelessWidget {

  const BasePage(this.page, {Key? key}) : super(key: key);
  final Widget page;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent,
        primaryColor: Colors.blue,
        cardColor: const Color(0xff1f2128), // Color.fromARGB(255, 40, 41, 46),
        dividerColor: const Color.fromARGB(255, 40, 41, 46),
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
      ),
      home: Container(
        color: const Color(0xff111216), //Color.fromARGB(255, 34, 36, 41),
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: Scaffold(
            extendBody: true,
            body: page,
          ),
        ),
      ),
    );
  }
}
