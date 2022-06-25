import 'package:flutter/material.dart';

class ColoredPage extends StatelessWidget {
  const ColoredPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: ColoredBox(
        color: const Color(0xff111216),
        child: child,
      ),
    );
  }
}
