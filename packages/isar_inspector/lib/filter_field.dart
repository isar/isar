import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'package:isar_inspector/app_state.dart';
import 'package:isar_inspector/query_parser.dart';
import 'package:provider/provider.dart';

class FilterField extends StatefulWidget {
  const FilterField({Key? key}) : super(key: key);

  @override
  State<FilterField> createState() => _FilterFieldState();
}

class _FilterFieldState extends State<FilterField> {
  final controller = TextEditingController();
  String? error;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Colors.white),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.all(20),
              errorText: error,
              hintText: 'Enter Query to filter the results',
              suffixIcon: IconButton(
                onPressed: controller.clear,
                icon: const Icon(Icons.clear),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
            style: GoogleFonts.sourceCodePro(),
          ),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: () {
            final appState = context.read<AppState>();
            final parser = QueryParser(appState.selectedCollection!.properties);
            try {
              if (controller.text.isEmpty) {
                appState.filter = const FilterGroup.or([]);
              } else {
                final filter = parser.parse(controller.text);
                appState.filter = filter;
                setState(() {
                  error = null;
                });
              }
            } catch (e) {
              setState(() {
                error = 'Invalid query';
              });
            }
          },
          child: const Text('Run'),
        )
      ],
    );
  }
}
