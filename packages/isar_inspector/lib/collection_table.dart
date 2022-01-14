import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:isar_inspector/app_state.dart';
import 'package:isar_inspector/common.dart';
import 'package:isar_inspector/prev_next.dart';
import 'package:isar_inspector/schema.dart';
import 'package:provider/provider.dart';

const _colWidths = {
  'Bool': 80.0,
  'Int': 80.0,
  'Float': 80.0,
  'Long': 80.0,
  'Double': 80.0,
  'String': 200.0,
  'Byte': 200.0,
  'Bytes': 200.0,
  'BoolList': 200.0,
  'IntList': 200.0,
  'FloatList': 200.0,
  'LongList': 200.0,
  'DoubleList': 200.0,
  'StringList': 200.0,
};

class CollectionTable extends StatefulWidget {
  const CollectionTable({Key? key}) : super(key: key);

  @override
  _CollectionTableState createState() => _CollectionTableState();
}

class _CollectionTableState extends State<CollectionTable> {
  final controller = ScrollController();

  @override
  void initState() {
    controller.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = Provider.of<AppState>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              children: [
                _buildHeader(theme, state),
                Expanded(
                  child: state.objects != null
                      ? _buildTable(theme, state)
                      : const Center(
                          child: CircularProgressIndicator(),
                        ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const PrevNext(),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme, AppState state) {
    return IsarCard(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var property in state.selectedCollection!.properties)
            _buildHeaderProperty(theme, state, property),
        ],
      ),
    );
  }

  Widget _buildHeaderProperty(
      ThemeData theme, AppState state, Property property) {
    return IsarCard(
      onTap: () {
        final state = Provider.of<AppState>(context, listen: false);
        if (state.sortProperty == property) {
          state.ascending = !state.ascending;
        } else {
          state.sortProperty = property;
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        child: SizedBox(
          width: _colWidths[property.type]!,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      property.type,
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (state.sortProperty == property)
                Icon(
                  state.ascending
                      ? FontAwesomeIcons.caretDown
                      : FontAwesomeIcons.caretUp,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTable(ThemeData theme, AppState state) {
    final objects = state.objects!;
    final collection = state.selectedCollection!;
    return ShaderMask(
      shaderCallback: (Rect rect) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            if (controller.offset <= 0) Colors.transparent else Colors.purple,
            Colors.transparent,
            Colors.transparent,
            if (controller.offset >= controller.position.maxScrollExtent)
              Colors.transparent
            else
              Colors.purple,
          ],
          stops: const [0.0, 0.05, 0.95, 1.0],
        ).createShader(rect);
      },
      blendMode: BlendMode.dstOut,
      child: SingleChildScrollView(
        controller: controller,
        child: Column(
          children: [
            for (var i = 0; i < objects.length; i++)
              _buildRow(theme, collection, objects[i], i),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(ThemeData theme, Collection collection,
      Map<String, Object> object, int index) {
    return IsarCard(
      color: index % 2 == 0 ? Colors.transparent : null,
      radius: BorderRadius.circular(15),
      onTap: () {},
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var property in collection.properties)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              child: SizedBox(
                width: _colWidths[property.type]!,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      object[property.name].toString(),
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
