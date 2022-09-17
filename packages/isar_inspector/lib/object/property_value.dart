import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';

class PropertyValue extends StatelessWidget {
  const PropertyValue(
    this.value, {
    super.key,
    required this.enumMap,
    required this.type,
    this.onUpdate,
  });

  final dynamic value;
  final IsarType type;
  final Map<String, dynamic>? enumMap;
  final void Function(dynamic newValue)? onUpdate;

  @override
  Widget build(BuildContext context) {
    final value = this.value;

    if (enumMap != null) {
      final enumName = enumMap!.entries.firstWhere(
        (e) => e.value == value,
        orElse: () {
          if (type == IsarType.byte || type == IsarType.byteList) {
            return enumMap!.entries.first;
          } else {
            return const MapEntry('null', null);
          }
        },
      ).key;
      return GestureDetector(
        onTapDown: onUpdate == null
            ? null
            : (TapDownDetails details) async {
                final newValue = await showMenu(
                  context: context,
                  position: RelativeRect.fromLTRB(
                    details.globalPosition.dx,
                    details.globalPosition.dy,
                    100000,
                    0,
                  ),
                  items: [
                    if (type != IsarType.byte && type != IsarType.byteList)
                      const PopupMenuItem<dynamic>(
                        child: Text('null'),
                      ),
                    for (final enumName in enumMap!.keys)
                      PopupMenuItem(
                        value: enumMap![enumName],
                        child: Text(enumName),
                      ),
                  ],
                );
                onUpdate?.call(newValue);
              },
        child: Text(
          enumName,
          style: GoogleFonts.jetBrainsMono(
            color: enumName != 'null' ? Colors.yellow : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    switch (type) {
      case IsarType.bool:
      case IsarType.boolList:
        return GestureDetector(
          onTapDown: onUpdate == null
              ? null
              : (TapDownDetails details) async {
                  final newValue = await showMenu(
                    context: context,
                    position: RelativeRect.fromLTRB(
                      details.globalPosition.dx,
                      details.globalPosition.dy,
                      100000,
                      0,
                    ),
                    items: const [
                      PopupMenuItem<bool?>(
                        child: Text('null'),
                      ),
                      PopupMenuItem(
                        value: true,
                        child: Text('true'),
                      ),
                      PopupMenuItem(
                        value: false,
                        child: Text('false'),
                      ),
                    ],
                  );
                  onUpdate?.call(newValue);
                },
          child: Text(
            '$value',
            style: GoogleFonts.jetBrainsMono(
              color: value != null ? Colors.orange : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      case IsarType.byte:
      case IsarType.byteList:
      case IsarType.int:
      case IsarType.intList:
      case IsarType.float:
      case IsarType.floatList:
      case IsarType.long:
      case IsarType.longList:
      case IsarType.double:
      case IsarType.doubleList:
        final numController = TextEditingController(
          text: value == null
              ? null
              : value == null
                  ? null
                  : '$value',
        );
        final numFocus = FocusNode();
        numFocus.addListener(() {
          if (!numFocus.hasPrimaryFocus) {
            final value = numController.text;
            num? numOrNull;
            if (type == IsarType.float ||
                type == IsarType.floatList ||
                type == IsarType.double ||
                type == IsarType.doubleList) {
              numOrNull = double.tryParse(value);
            } else {
              numOrNull = int.tryParse(value);
            }
            onUpdate?.call(numOrNull);
          }
        });
        return TextField(
          controller: numController,
          focusNode: numFocus,
          enabled: onUpdate != null,
          decoration: InputDecoration.collapsed(
            hintText: 'null',
            hintStyle: GoogleFonts.jetBrainsMono(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          style: GoogleFonts.jetBrainsMono(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        );
      case IsarType.dateTime:
      case IsarType.dateTimeList:
        final date = value != null
            ? DateTime.fromMicrosecondsSinceEpoch(value as int)
            : null;
        return GestureDetector(
          onTap: onUpdate == null
              ? null
              : () async {
                  final newDate = await showDatePicker(
                    context: context,
                    initialDate: date ?? DateTime.now(),
                    firstDate: DateTime(1970),
                    lastDate: DateTime(2050),
                  );
                  onUpdate?.call(newDate?.microsecondsSinceEpoch);
                },
          child: Text(
            date?.toIso8601String() ?? 'null',
            style: GoogleFonts.jetBrainsMono(
              color: date != null ? Colors.blue : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      case IsarType.string:
      case IsarType.stringList:
        final strController = TextEditingController(
          text: value == null
              ? null
              : '"${value.toString().replaceAll('\n', '⤵')}"',
        );
        final strFocus = FocusNode();
        strFocus.addListener(() {
          if (!strFocus.hasPrimaryFocus) {
            final value = strController.text;
            String? strOrNull;
            if (value.startsWith('"') && value.endsWith('"')) {
              strOrNull =
                  value.substring(1, value.length - 1).replaceAll('⤵', '\n');
            }
            onUpdate?.call(strOrNull);
          }
        });
        return TextField(
          controller: strController,
          focusNode: strFocus,
          enabled: onUpdate != null,
          decoration: InputDecoration.collapsed(
            hintText: 'null',
            hintStyle: GoogleFonts.jetBrainsMono(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          style: GoogleFonts.jetBrainsMono(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        );
      case IsarType.object:
      case IsarType.objectList:
        throw ArgumentError('Invalid type');
    }
  }
}

class NullValue extends StatelessWidget {
  const NullValue({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'null',
      style: GoogleFonts.jetBrainsMono(
        color: Colors.grey,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
