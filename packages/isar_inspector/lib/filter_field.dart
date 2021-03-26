import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar_inspector/app_state.dart';
import 'package:isar_inspector/query_parser.dart';
import 'package:provider/provider.dart';

class FilterField extends StatefulWidget {
  @override
  _FilterFieldState createState() => _FilterFieldState();
}

class _FilterFieldState extends State<FilterField> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              contentPadding: EdgeInsets.all(20),
            ),
            style: GoogleFonts.sourceCodePro(),
          ),
        ),
        SizedBox(width: 20),
        ElevatedButton(
          onPressed: () {
            final appState = context.read<AppState>();
            final parser = QueryParser(appState.selectedCollection!.properties);
            try {
              final filter = parser.parse(controller.text);
              appState.filter = filter;
            } catch (e) {
              print(e);
            }
          },
          child: Text('Run'),
        )
      ],
    );
  }
}
