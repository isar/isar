import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'common.dart';

import 'state/instances_state.dart';

class InstanceSelector extends ConsumerStatefulWidget {
  const InstanceSelector({Key? key}) : super(key: key);

  @override
  ConsumerState<InstanceSelector> createState() => _InstanceSelectorState();
}

class _InstanceSelectorState extends ConsumerState<InstanceSelector>
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
    final instances = ref.watch(instancesPod).value!;
    final selectedInstance = ref.watch(selectedInstancePod).value!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Padding(
              padding: const EdgeInsets.all(1),
              child: IsarCard(
                color: const Color(0xff31343f),
                radius: BorderRadius.circular(15),
                child: SizeTransition(
                  sizeFactor: _animation,
                  axisAlignment: -1,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 15),
                      for (var instance in instances)
                        if (instance != selectedInstance)
                          InstanceButton(
                            instance: instance,
                            onTap: () {
                              ref.read(selectedInstanceNamePod.state).state =
                                  instance;
                              _controller.reverse();
                            },
                          ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
            SelectedInstanceButton(
              instance: selectedInstance,
              hasMultiple: instances.length > 1,
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
    Key? key,
    required this.instance,
    required this.onTap,
  }) : super(key: key);
  final String instance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: IsarCard(
        color: Colors.transparent,
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
    );
  }
}

class SelectedInstanceButton extends StatelessWidget {

  const SelectedInstanceButton({
    Key? key,
    required this.instance,
    required this.onTap,
    required this.hasMultiple,
    required this.color,
  }) : super(key: key);
  final String instance;
  final VoidCallback onTap;
  final bool hasMultiple;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 65,
      child: IsarCard(
        color: color,
        radius: BorderRadius.circular(15),
        onTap: hasMultiple ? onTap : null,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(
                  FontAwesomeIcons.database,
                  size: 25,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      instance,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Text('Isar Instance')
                  ],
                ),
                const Spacer(),
                if (hasMultiple)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
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
