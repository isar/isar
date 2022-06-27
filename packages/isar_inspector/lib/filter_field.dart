import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';

import 'package:isar_inspector/query_parser.dart';
import 'package:isar_inspector/schema.dart';
import 'package:isar_inspector/state/collections_state.dart';
import 'package:isar_inspector/state/instances_state.dart';
import 'package:isar_inspector/state/isar_connect_state_notifier.dart';
import 'package:isar_inspector/state/query_state.dart';

class FilterField extends ConsumerStatefulWidget {
  const FilterField({super.key});

  @override
  ConsumerState<FilterField> createState() => _FilterFieldState();
}

class _FilterFieldState extends ConsumerState<FilterField> {
  final TextEditingController controller = TextEditingController();
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
            final selectedCollection = ref.read(selectedCollectionPod).value1;
            final filter = _parseFilter(selectedCollection);
            ref.read(queryFilterPod.state).state = filter;
            ref.read(queryPagePod.state).state = 0;
          },
          child: const Text('Query'),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: () {
            final selectedCollection = ref.read(selectedCollectionPod).value1;
            final filter = _parseFilter(selectedCollection);
            final query = ConnectQuery(
              instance: ref.read(selectedInstancePod).value1,
              collection: selectedCollection.name,
              filter: filter,
            );
            ref.read(isarConnectPod.notifier).removeQuery(query);
          },
          child: const Text('Remove'),
        )
      ],
    );
  }

  FilterOperation? _parseFilter(ICollection collection) {
    final parser = QueryParser(collection.properties);
    FilterOperation? newFilter;
    try {
      if (controller.text.isNotEmpty) {
        final filter = parser.parse(controller.text);
        newFilter = filter;
      }

      setState(() {
        error = null;
      });

      return newFilter;
    } catch (e) {
      setState(() {
        error = 'Invalid query';
      });
    }

    return null;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
