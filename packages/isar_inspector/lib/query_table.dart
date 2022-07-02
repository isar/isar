import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_treeview/flutter_treeview.dart';
import 'package:isar/isar.dart';

import 'package:isar_inspector/common.dart';
import 'package:isar_inspector/prev_next.dart';
import 'package:isar_inspector/schema.dart';
import 'package:isar_inspector/state/collections_state.dart';
import 'package:isar_inspector/state/instances_state.dart';
import 'package:isar_inspector/state/isar_connect_state_notifier.dart';
import 'package:isar_inspector/state/query_state.dart';

const _stringColor = Color(0xFF6A8759);
const _numberColor = Color(0xFF6897BB);
const _boolColor = Color(0xFFCC7832);
const _disableColor = Colors.grey;

class QueryTable extends ConsumerWidget {
  QueryTable({super.key});

  final _controller = ScrollController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collection = ref.watch(selectedCollectionPod).value!;
    final objects = ref.watch(queryResultsPod).value?.objects ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: RawScrollbar(
            controller: _controller,
            thumbColor: Colors.grey,
            child: ListView.separated(
              controller: _controller,
              itemCount: objects.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    TableBlock(
                      key: Key(objects[index].hashCode.toString()),
                      collection: collection,
                      object: objects[index],
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10, right: 10),
                        child: Tooltip(
                          message: 'Delete object',
                          child: IconButton(
                            icon: const Icon(Icons.delete),
                            splashRadius: 25,
                            onPressed: () {
                              final collection =
                                  ref.read(selectedCollectionPod).valueOrNull;
                              if (collection == null) {
                                return;
                              }

                              final query = ConnectQuery(
                                instance: ref.read(selectedInstancePod).value!,
                                collection: collection.name,
                                filter: FilterCondition.equalTo(
                                  property: collection.idName,
                                  value: objects[index].getValue(
                                    collection.idName,
                                  ),
                                ),
                              );
                              ref
                                  .read(isarConnectPod.notifier)
                                  .removeQuery(query);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
              separatorBuilder: (BuildContext context, int index) {
                return const SizedBox(height: 15);
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        const PrevNext(),
      ],
    );
  }
}

class TableBlock extends StatefulWidget {
  const TableBlock({
    super.key,
    required this.collection,
    required this.object,
  });

  final ICollection collection;
  final QueryObject object;

  @override
  State<TableBlock> createState() => _TableBlockState();
}

class _TableBlockState extends State<TableBlock> {
  late TreeViewController _treeViewController = TreeViewController(
    children: widget.collection.allProperties.map((property) {
      final children = <Node<TreeViewHelper>>[];
      final rawValue = widget.object.getValue(property.name);
      String value;
      Color color;

      switch (property.type) {
        case IsarType.Bool:
          value = rawValue.toString();
          color = _boolColor;
          break;

        case IsarType.Int:
        case IsarType.Float:
        case IsarType.Long:
        case IsarType.Double:
          value = rawValue.toString();
          color = _numberColor;
          break;

        case IsarType.String:
          value = '"$rawValue"';
          color = _stringColor;
          break;

        case IsarType.ByteList:
        case IsarType.IntList:
        case IsarType.FloatList:
        case IsarType.BoolList:
        case IsarType.LongList:
        case IsarType.DoubleList:
        case IsarType.StringList:
          final list = rawValue as List<dynamic>;

          value = '${property.type.toString().replaceAll('IsarType.', '')}'
              ' [${list.length}]';
          color = _disableColor;

          for (var index = 0; index < list.length; index++) {
            children.add(
              Node(
                key: '${property.name}_$index',
                label: '',
                data: TreeViewHelper(
                  name: index.toString(),
                  value: property.type == IsarType.StringList
                      ? '"${list[index]}"'
                      : list[index].toString(),
                  rawValue: list[index],
                  valueColor: property.type == IsarType.StringList
                      ? _stringColor
                      : property.type == IsarType.BoolList
                          ? _boolColor
                          : _numberColor,
                ),
              ),
            );
          }
          break;
      }

      return Node<TreeViewHelper>(
        key: property.name,
        label: '',
        children: children,
        data: TreeViewHelper(
          name: property.name,
          value: value,
          rawValue: rawValue,
          valueColor: color,
        ),
      );
    }).toList(),
  );

  @override
  Widget build(BuildContext context) {
    return IsarCard(
      color: const Color(0xFF1F2128),
      padding: const EdgeInsets.fromLTRB(25, 15, 15, 15),
      radius: BorderRadius.circular(5),
      child: TreeView(
        theme: const TreeViewTheme(
          expanderTheme: ExpanderThemeData(color: Colors.white),
        ),
        controller: _treeViewController,
        shrinkWrap: true,
        nodeBuilder: (context, node) {
          return TableItem(data: node.data as TreeViewHelper);
        },
        onExpansionChanged: (key, expanded) {
          _expanding(_treeViewController.getNode(key)!, expanded);
        },
        onNodeTap: (key) {
          final node = _treeViewController.getNode<TreeViewHelper>(key)!;
          _expanding(node, !node.expanded);
        },
      ),
    );
  }

  void _expanding(Node<TreeViewHelper> node, bool expanded) {
    setState(() {
      _treeViewController = _treeViewController.copyWith(
        children: _treeViewController.updateNode(
          node.key,
          node.copyWith(expanded: expanded),
        ),
      );
    });
  }
}

class TableItem extends StatefulWidget {
  const TableItem({super.key, required this.data});

  final TreeViewHelper data;

  @override
  State<TableItem> createState() => _TableItemState();
}

class _TableItemState extends State<TableItem> {
  bool _entered = false;

  @override
  Widget build(BuildContext context) {
    final richText = RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        text: '${widget.data.name}: ',
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        children: [
          TextSpan(
            text: widget.data.value,
            style: TextStyle(color: widget.data.valueColor),
          )
        ],
      ),
    );

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _entered = true;
        });
      },
      onExit: (e) {
        setState(() {
          _entered = false;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: widget.data.rawValue is String
                  ? Tooltip(
                      message: widget.data.value,
                      child: richText,
                    )
                  : richText,
            ),
            if (_entered)
              InkWell(
                onTap: () async {
                  ScaffoldMessenger.of(context).removeCurrentSnackBar();

                  await Clipboard.setData(
                    ClipboardData(text: widget.data.rawValue.toString()),
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        duration: Duration(seconds: 1),
                        width: 200,
                        behavior: SnackBarBehavior.floating,
                        content: Text(
                          'Copied To Clipboard',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }
                },
                child: const Center(
                  child: Tooltip(
                    message: 'Copy to clipboard',
                    child: Icon(Icons.copy, size: 18),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TreeViewHelper {
  const TreeViewHelper({
    required this.name,
    required this.value,
    required this.rawValue,
    required this.valueColor,
  });

  final String name;
  final String value;
  final dynamic rawValue;
  final Color valueColor;
}
