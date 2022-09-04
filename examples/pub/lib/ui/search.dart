import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class Search extends StatefulWidget {
  const Search({super.key, required this.onSearch, this.query});

  final String? query;
  final void Function(String query) onSearch;

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  late final textController = TextEditingController(text: widget.query);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: SvgPicture.asset(
            'assets/search_bg.svg',
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: SafeArea(
            bottom: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      context.go('/');
                    },
                    child: SvgPicture.asset(
                      'assets/pub_logo_dark.svg',
                      width: 250,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 40,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xff35404d),
                      borderRadius: BorderRadius.all(Radius.circular(50)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.grey),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Center(
                              child: TextField(
                                controller: textController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Search packages',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                onSubmitted: (query) {
                                  if (query.isNotEmpty) {
                                    widget.onSearch(query);
                                  }
                                },
                                onEditingComplete: () {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}
