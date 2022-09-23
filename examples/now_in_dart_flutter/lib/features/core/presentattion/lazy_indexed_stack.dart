import 'package:flutter/material.dart';

/// IndexedStack but lazy.
///
/// Source code credit: [marcossevilla](https://github.com/marcossevilla/lazy_indexed_stack/blob/main/lib/src/flutter_lazy_indexed_stack.dart)
class LazyIndexedStack extends StatefulWidget {
  const LazyIndexedStack({
    super.key,
    this.index = 0,
    this.children = const [],
  });

  final int? index;

  final List<Widget> children;

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late final List<bool> _activatedChildren;

  @override
  void initState() {
    super.initState();
    _activatedChildren = List.generate(
      widget.children.length,
      (i) => i == widget.index,
    );
  }

  @override
  void didUpdateWidget(LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) _activateChild(widget.index);
  }

  void _activateChild(int? index) {
    if (index == null) return;

    if (!_activatedChildren[index]) {
      setState(() => _activatedChildren[index] = true);
    }
  }

  List<Widget> get children {
    return List.generate(
      widget.children.length,
      (i) {
        return _activatedChildren[i]
            ? widget.children[i]
            : const SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      children: children,
    );
  }
}
