import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_treeview/flutter_treeview.dart';
import 'package:isar/isar.dart';

import 'package:isar_inspector/common.dart';
import 'package:isar_inspector/edit_popup.dart';
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

typedef Editor = void Function(
  int id,
  String property,
  int? index,
  dynamic value,
);

class QueryTable extends ConsumerWidget {
  QueryTable({super.key});

  final _controller = ScrollController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collection = ref.watch(selectedCollectionPod).value!;
    final objects = ref.watch(queryResultsPod).value?.objects ?? [];

    if (objects.isEmpty ||
        collection.allProperties.length != objects[0].data.length) {
      return Container();
    }

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
                      key: ValueKey('${collection.name}'
                          '_${objects[index].getValue(collection.idName)}'),
                      collection: collection,
                      object: objects[index],
                      editor: (id, property, index, value) {
                        final edit = ConnectEdit(
                          instance: ref.read(selectedInstancePod).value!,
                          collection: collection.name,
                          id: id,
                          property: property,
                          index: index,
                          value: value,
                        );
                        ref.read(isarConnectPod.notifier).editProperty(edit);
                      },
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
    required super.key,
    required this.collection,
    required this.object,
    required this.editor,
  });

  final ICollection collection;
  final QueryObject object;
  final Editor editor;

  @override
  State<TableBlock> createState() => _TableBlockState();
}

class _TableBlockState extends State<TableBlock> {
  late final int _id = widget.object.getValue(widget.collection.idName) as int;
  TreeViewController _treeViewController = TreeViewController();

  @override
  Widget build(BuildContext context) {
    _updateNodes();
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
          return TableItem(
            data: node.data as TreeViewHelper,
            editor: widget.editor,
            objectId: _id,
          );
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

  void _updateNodes() {
    _treeViewController = _treeViewController.copyWith(
      children: widget.collection.allProperties.map((property) {
        final children = <Node<TreeViewHelper>>[];
        final value = widget.object.getValue(property.name);

        if (property.type.isList) {
          final list = value as List<dynamic>;

          for (var index = 0; index < list.length; index++) {
            children.add(
              Node(
                key: '${property.name}_$index',
                label: '',
                data: TreeViewHelper(
                  property: IProperty(
                    name: property.name,
                    type: property.type.childType,
                  ),
                  value: list[index],
                  index: index,
                ),
              ),
            );
          }
        }

        return Node<TreeViewHelper>(
          key: property.name,
          label: '',
          children: children,
          data: TreeViewHelper(
            property: property,
            value: value,
          ),
        );
      }).toList(),
    );
  }
}

class TableItem extends StatefulWidget {
  const TableItem({
    super.key,
    required this.data,
    required this.editor,
    required this.objectId,
  });

  final TreeViewHelper data;
  final int objectId;
  final Editor editor;

  @override
  State<TableItem> createState() => _TableItemState();
}

class _TableItemState extends State<TableItem> {
  bool _entered = false;

  @override
  Widget build(BuildContext context) {
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
              child: widget.data.value is String
                  ? Tooltip(
                      message: widget.data.value.toString(),
                      child: _createText(),
                    )
                  : _createText(),
            ),
            if (_entered) ...[
              if (!widget.data.property.isId &&
                  !widget.data.property.type.isList) ...[
                GestureDetector(
                  onTap: () async {
                    final result = await showDialog<Map<String, dynamic>?>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          content: EditPopup(
                            type: widget.data.property.type,
                            value: widget.data.value,
                            enableNull: widget.data.index == null,
                          ),
                        );
                      },
                    );

                    if (result != null) {
                      widget.editor(
                        widget.objectId,
                        widget.data.property.name,
                        widget.data.index,
                        result['value'],
                      );
                    }
                  },
                  child: const Tooltip(
                    message: 'Edit property',
                    child: Icon(Icons.edit, size: 18),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              GestureDetector(
                onTap: () async {
                  ScaffoldMessenger.of(context).removeCurrentSnackBar();

                  await Clipboard.setData(
                    ClipboardData(text: widget.data.value.toString()),
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
          ],
        ),
      ),
    );
  }

  Widget _createText() {
    var value = '';
    var color = Colors.white;

    if (widget.data.value == null) {
      value = 'null';
      color = _boolColor;
    } else {
      switch (widget.data.property.type) {
        case IsarType.Bool:
          value = widget.data.value.toString();
          color = _boolColor;
          break;

        case IsarType.Byte:
        case IsarType.Int:
        case IsarType.Float:
        case IsarType.Long:
        case IsarType.Double:
          value = widget.data.value.toString();
          color = _numberColor;
          break;

        case IsarType.String:
          value = '"${widget.data.value.toString().replaceAll('\n', '⤵')}"';
          color = _stringColor;
          break;

        case IsarType.ByteList:
        case IsarType.IntList:
        case IsarType.FloatList:
        case IsarType.LongList:
        case IsarType.DoubleList:
        case IsarType.StringList:
        case IsarType.BoolList:
          value = '${widget.data.property.type.name}'
              ' [${(widget.data.value as List).length}]';
          color = _disableColor;
      }
    }

    return RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        text: '${widget.data.index ?? widget.data.property.name}: ',
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        children: [
          TextSpan(
            text: value,
            style: TextStyle(color: color),
          ),
        ],
      ),
    );
  }
}

class TreeViewHelper {
  const TreeViewHelper({
    required this.property,
    required this.value,
    this.index,
  });

  final IProperty property;
  final dynamic value;
  final int? index;
}
