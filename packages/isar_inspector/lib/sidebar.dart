import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:isar_inspector/app_state.dart';
import 'package:isar_inspector/collections.dart';
import 'package:isar_inspector/common.dart';
import 'package:isar_inspector/instance_selector.dart';
import 'package:provider/provider.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({Key? key}) : super(key: key);

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 400),
    vsync: this,
  );

  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  bool _connected = false;

  @override
  void initState() {
    _animation.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        Provider.of<AppState>(context, listen: false).sidebarExpanded = false;
      }
      if (status == AnimationStatus.completed) {
        Provider.of<AppState>(context, listen: false).sidebarExpanded = true;
      }
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
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (state.connected != _connected) {
          if (state.connected) {
            _controller.forward();
          } else {
            _controller.reverse();
          }
          _connected = state.connected;
        }
        return LayoutBuilder(
          builder: (_, constraints) {
            return Column(
              children: [
                IsarCard(
                  radius: BorderRadius.circular(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 80,
                        child: _buildHeader(state.connected),
                      ),
                      SizeTransition(
                        sizeFactor: _animation,
                        axis: Axis.vertical,
                        axisAlignment: -1,
                        child: SizedBox(
                          height: constraints.maxHeight - 80,
                          child: Column(
                            children: const [
                              SizedBox(height: 20),
                              Expanded(child: CollectionsList()),
                              SizedBox(height: 12),
                              InstanceSelector(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(bool connected) {
    return IsarCard(
      radius: BorderRadius.circular(15),
      onTap: connected
          ? () {
              setState(() {
                if (_controller.status == AnimationStatus.completed) {
                  _controller.reverse();
                } else {
                  _controller.forward();
                }
              });
            }
          : null,
      onLongPress: () {
        Provider.of<AppState>(context, listen: false).service?.disconnect();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/logo.svg',
              width: 40,
            ),
            const SizedBox(width: 15),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Isar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Inspector',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
