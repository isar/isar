import 'package:flutter/material.dart';

class SortButtons extends StatelessWidget {
  const SortButtons({
    required this.properties,
    required this.selectedProperty,
    required this.asc,
    required this.onChanged,
    super.key,
  });

  final List<String> properties;
  final String selectedProperty;
  final bool asc;
  final void Function(String property, bool asc) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Sort results by this property',
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isDense: true,
              items: [
                for (final property in properties)
                  DropdownMenuItem(
                    value: property,
                    child: Text(property),
                  ),
              ],
              value: selectedProperty,
              onChanged: (value) {
                if (value != null) {
                  onChanged(value, asc);
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 10),
        ActionChip(
          label: Text(asc ? 'Asc' : 'Desc'),
          onPressed: () {
            onChanged(selectedProperty, !asc);
          },
          tooltip: 'Toggle sort order',
        ),
      ],
    );
  }
}
