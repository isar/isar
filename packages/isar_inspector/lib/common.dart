import 'package:flutter/material.dart';

class IsarCard extends StatelessWidget {
  IsarCard({
    super.key,
    required this.child,
    this.color,
    this.onTap,
    this.onLongPress,
    BorderRadius? radius,
  }) : radius = radius ?? BorderRadius.circular(20);
  final Widget child;
  final Color? color;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: child,
      ),
    );
  }
}
