import 'package:flutter/material.dart';
import 'package:isar_inspector/common.dart';
import 'package:isar_inspector/schema.dart';

class EditPopup extends StatefulWidget {
  const EditPopup({
    super.key,
    required this.type,
    required this.value,
    required this.enableNull,
  });

  final IsarType type;
  final dynamic value;
  final bool enableNull;

  @override
  State<EditPopup> createState() => _EditPopupState();
}

class _EditPopupState extends State<EditPopup> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  final _focus = FocusNode();
  CustomTextInputFormatter? _inputFormatter;

  bool? _boolValue;
  bool _null = false;

  @override
  void initState() {
    if (widget.enableNull && widget.value == null) {
      _null = true;
    }

    if (widget.type == IsarType.Bool) {
      _boolValue = _null || widget.value as bool;
    } else {
      _controller.text = _null ? '' : widget.value.toString();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );

      if (widget.type != IsarType.String) {
        _inputFormatter = CustomTextInputFormatter(widget.type);
      }

      if (!_null) {
        _focus.requestFocus();
      }
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.type == IsarType.String ? 500 : 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.enableNull) ...[
            CheckboxListTile(
              value: _null,
              title: const Text('NULL'),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _null = value;
                  });
                }
              },
            ),
            const SizedBox(height: 15),
          ],
          if (widget.type == IsarType.Bool)
            DropdownButtonHideUnderline(
              child: DropdownButton<bool>(
                value: _boolValue,
                items: const [
                  DropdownMenuItem(
                    value: true,
                    child: Text('TRUE'),
                  ),
                  DropdownMenuItem(
                    value: false,
                    child: Text('FALSE'),
                  ),
                ],
                onChanged: _null
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _boolValue = value;
                          });
                        }
                      },
              ),
            )
          else
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _controller,
                focusNode: _focus,
                enabled: !_null,
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  contentPadding: const EdgeInsets.all(20),
                ),
                inputFormatters: [
                  if (_inputFormatter != null) _inputFormatter!
                ],
                maxLines: widget.type == IsarType.String ? 3 : 1,
                validator: (value) {
                  if (widget.type == IsarType.Byte) {
                    final val = int.parse(value!);
                    if (val < 0 || val > 255) {
                      return 'Byte values must between 0-255';
                    }
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _save(),
              ),
            ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(onPressed: _save, child: const Text('Save')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _save() {
    dynamic value;

    if (_null) {
      value = null;
    } else {
      if (widget.type == IsarType.Bool) {
        value = _boolValue;
      } else {
        if (_formKey.currentState!.validate()) {
          //ignore: missing_enum_constant_in_switch
          switch (widget.type) {
            case IsarType.Float:
            case IsarType.Double:
              value = double.tryParse(_controller.text) ?? 0.0;
              break;

            case IsarType.Byte:
            case IsarType.Int:
            case IsarType.Long:
              value = int.tryParse(_controller.text) ?? 0;
              break;
          }
          value ??= _controller.text;
        } else {
          return;
        }
      }
    }

    Navigator.pop(context, {'value': value});
  }
}
