import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:isar_inspector/app_state.dart';
import 'package:isar_inspector/common.dart';
import 'package:provider/provider.dart';

class InstanceSelector extends StatefulWidget {
  @override
  _InstanceSelectorState createState() => _InstanceSelectorState();
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
    _animation.addStatusListener((status) {
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
    final state = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Padding(
              padding: const EdgeInsets.all(1),
              child: IsarCard(
                color: Color(0xff31343f),
                radius: BorderRadius.circular(15),
                child: SizeTransition(
                  sizeFactor: _animation,
                  axis: Axis.vertical,
                  axisAlignment: -1,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 15),
                      for (var instance in state.instances!
                          .where((e) => e != state.selectedInstance))
                        _buildInstanceButton(theme, instance),
                      SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
            _buildSelectedInstanceButton(state.selectedInstance!),
          ],
        ),
      ],
    );
  }

  Widget _buildInstanceButton(ThemeData theme, String instance) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: IsarCard(
        color: Colors.transparent,
        onTap: () {
          context.read<AppState>().selectedInstance = instance;
          _controller.reverse();
        },
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              instance,
              textAlign: TextAlign.start,
              style: TextStyle(
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

  Widget _buildSelectedInstanceButton(String selectedInstance) {
    return SizedBox(
      height: 65,
      child: IsarCard(
        color:
            _animation.status != AnimationStatus.dismissed ? Colors.blue : null,
        radius: BorderRadius.circular(15),
        onTap: () {
          if (context.read<AppState>().instances!.length > 1) {
            if (_controller.status == AnimationStatus.completed) {
              _controller.reverse();
            } else {
              _controller.forward();
            }
          }
        },
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  FontAwesomeIcons.database,
                  size: 25,
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      selectedInstance,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text('Isar Instance')
                  ],
                ),
                Spacer(),
                Column(
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
