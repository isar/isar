import 'package:flutter/material.dart';
import 'package:isar_inspector/app_state.dart';
import 'package:isar_inspector/common.dart';
import 'package:provider/provider.dart';

class PrevNext extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _button(context, false),
        SizedBox(width: 20),
        _button(context, true),
      ],
    );
  }

  Widget _button(BuildContext context, bool next) {
    final state = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    final enabled = next ? state.hasMore : state.offset != 0;
    return IsarCard(
      color: Colors.transparent,
      radius: BorderRadius.circular(15),
      onTap: enabled
          ? () {
              Provider.of<AppState>(context, listen: false).nextPage();
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Text(
          next ? 'Next' : 'Prev',
          style: TextStyle(
            color: enabled ? theme.primaryColor : null,
          ),
        ),
      ),
    );
  }
}
