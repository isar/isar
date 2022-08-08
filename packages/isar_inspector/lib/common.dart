import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';

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
            onTap: onChanged != null ? () => onChanged!(!value) : null,
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

class CustomTextInputFormatter extends TextInputFormatter {
  CustomTextInputFormatter(this.type) {
    if (type == IsarType.byte) {
      _callback = _byte;
    } else if (type == IsarType.long || type == IsarType.int) {
      _callback = _int;
    } else if (type == IsarType.double || type == IsarType.float) {
      _callback = _double;
    } else {
      throw IsarError('new IsarType (${type.name}), rule not defined');
    }
  }

  final IsarType type;
  late TextEditingValue Function(TextEditingValue, TextEditingValue) _callback;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return _callback(oldValue, newValue);
  }

  TextEditingValue _byte(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty ||
        newValue.text.length <= 3 && int.tryParse(newValue.text) != null) {
      return newValue;
    }
    return oldValue;
  }

  TextEditingValue _int(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty ||
        (newValue.text.length == 1 && newValue.text == '-') ||
        int.tryParse(newValue.text) != null) {
      return newValue;
    }

    return oldValue;
  }

  TextEditingValue _double(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty ||
        (newValue.text.length == 1 && newValue.text == '-') ||
        double.tryParse(newValue.text) != null) {
      return newValue;
    }

    return oldValue;
  }
}
