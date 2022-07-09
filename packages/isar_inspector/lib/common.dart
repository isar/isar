import 'package:flutter/material.dart';

class IsarCard extends StatelessWidget {
  IsarCard({
    super.key,
    required this.child,
    this.color,
    this.onTap,
    this.onLongPress,
    this.side = BorderSide.none,
    this.padding = EdgeInsets.zero,
    BorderRadius? radius,
  }) : radius = radius ?? BorderRadius.circular(20);

  final Widget child;
  final Color? color;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius radius;
  final BorderSide side;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: radius, side: side),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: Padding(
        padding: padding,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: child,
        ),
      ),
    );
  }
}

class CheckBoxLabel extends StatelessWidget {
  const CheckBoxLabel({
  super.key,
  required this.value,
  required this.text,
  this.padding = EdgeInsets.zero,
  required this.onChanged,
  });

  final String text;
  final bool value;
  final EdgeInsets padding;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          InkWell(
            onTap: onChanged != null
                ? () => onChanged!(!value)
                : null,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  AbsorbPointer(
                    child: ExcludeFocus(
                      child: Checkbox(
                        value: value,
                        onChanged: onChanged != null ? (value) {} : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
