import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'collections.dart';
import 'common.dart';
import 'instance_selector.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IsarCard(
      radius: BorderRadius.circular(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 80,
            child: IsarCard(
              radius: BorderRadius.circular(15),
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
            ),
          ),
          const SizedBox(height: 20),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: CollectionsList(),
            ),
          ),
          const SizedBox(height: 12),
          const InstanceSelector(),
        ],
      ),
    );
  }
}
