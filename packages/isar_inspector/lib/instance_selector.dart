import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class InstanceSelector extends StatefulWidget {
  const InstanceSelector({
    required this.instances,
    required this.selectedInstance,
    required this.onSelected,
    super.key,
  });

  final List<String> instances;
  final String? selectedInstance;
  final void Function(String instance) onSelected;

  @override
  State<InstanceSelector> createState() => _InstanceSelectorState();
}

class _InstanceSelectorState extends State<InstanceSelector>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );

  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    _animation.addStatusListener((AnimationStatus status) {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Card(
              margin: const EdgeInsets.all(10),
              color: theme.colorScheme.secondaryContainer,
              child: SizeTransition(
                sizeFactor: _animation,
                axisAlignment: -1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    for (final instance in widget.instances)
                      if (instance != widget.selectedInstance)
                        InstanceButton(
                          instance: instance,
                          onTap: () {
                            widget.onSelected(instance);
                            _controller.reverse();
                          },
                        ),
                    const SizedBox(height: 75),
                  ],
                ),
              ),
            ),
            if (widget.selectedInstance != null)
              SelectedInstanceButton(
                instance: widget.selectedInstance!,
                hasMultiple: widget.instances.length > 1,
                color: _animation.status != AnimationStatus.dismissed
                    ? Colors.blue
                    : null,
                onTap: () {
                  if (_controller.status == AnimationStatus.completed) {
                    _controller.reverse();
                  } else {
                    _controller.forward();
                  }
                },
              ),
          ],
        ),
      ],
    );
  }
}

class InstanceButton extends StatelessWidget {
  const InstanceButton({
    required this.instance,
    required this.onTap,
    super.key,
  });

  final String instance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Card(
        margin: EdgeInsets.zero,
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                instance,
                textAlign: TextAlign.start,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SelectedInstanceButton extends StatelessWidget {
  const SelectedInstanceButton({
    required this.instance,
    required this.onTap,
    required this.hasMultiple,
    required this.color,
    super.key,
  });

  final String instance;
  final VoidCallback onTap;
  final bool hasMultiple;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(10),
      color: theme.colorScheme.secondaryContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: hasMultiple ? onTap : null,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Icon(
                  FontAwesomeIcons.database,
                  size: 25,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      instance,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    Text(
                      'Isar Instance',
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (hasMultiple)
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        FontAwesomeIcons.chevronUp,
                        size: 12,
                      ),
                      Icon(
                        FontAwesomeIcons.chevronDown,
                        size: 12,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
