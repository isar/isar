import 'package:flutter/material.dart';
import 'package:now_in_dart_flutter/features/detail/flutter_detail/presentation/view/flutter_release_notes_page.dart';
import 'package:now_in_dart_flutter/features/detail/flutter_detail/presentation/view/flutter_whats_new_page.dart';

class FlutterDetailPage extends StatelessWidget {
  const FlutterDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    const tabs = [
      Tab(text: "What's new 🆕"),
      Tab(text: 'Release Notes 🗒️'),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter'),
          bottom: const TabBar(
            tabs: tabs,
          ),
        ),
        body: const TabBarView(
          children: [
            FlutterWhatsNewPage(),
            FlutterReleaseNotesPage(),
          ],
        ),
      ),
    );
  }
}
