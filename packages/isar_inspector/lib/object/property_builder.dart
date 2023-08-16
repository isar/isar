import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PropertyBuilder extends StatefulWidget {
  const PropertyBuilder({
    required this.property,
    required this.type,
    super.key,
    this.bold = false,
    this.underline = false,
    this.value,
    this.children = const [],
  });

  final String property;
  final bool bold;
  final bool underline;
  final Widget? value;
  final String type;
  final List<Widget> children;

  @override
  State<PropertyBuilder> createState() => _PropertyBuilderState();
}

class _PropertyBuilderState extends State<PropertyBuilder> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: widget.children.isNotEmpty
              ? () => setState(() => _expanded = !_expanded)
              : null,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            child: Row(
              children: [
                if (widget.children.isNotEmpty) ...[
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.arrow_right,
                      size: 24,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 4),
                ] else
                  const SizedBox(width: 28),
                Tooltip(
                  message: widget.type,
                  child: Text(
                    '${widget.property}:',
                    style: GoogleFonts.jetBrainsMono(
                      fontWeight: widget.bold ? FontWeight.w800 : null,
                      color: theme.colorScheme.onPrimaryContainer,
                      decoration:
                          widget.underline ? TextDecoration.underline : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.value != null)
                  Expanded(child: widget.value!)
                else
                  Text(
                    widget.type,
                    style: TextStyle(
                      color:
                          theme.colorScheme.onPrimaryContainer.withOpacity(0.5),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_expanded && widget.children.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Column(children: widget.children),
            ),
          ),
      ],
    );
  }
}
