import 'package:clickup_fading_scroll/clickup_fading_scroll.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_svg/flutter_html_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher_string.dart';

final _markdownHtmlPod = Provider.family<String, String>((ref, source) {
  return md.markdownToHtml(
    source,
    extensionSet: md.ExtensionSet.gitHubWeb,
  );
});

class MarkdownViewer extends ConsumerWidget {
  const MarkdownViewer({super.key, required this.markdown});

  final String markdown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final html = ref.read(_markdownHtmlPod(markdown));
    return Html(
      data: html,
      onLinkTap: (url, attributes, element) {
        if (url != null) {
          launchUrlString(url);
        }
      },
      extensions: [
        const SvgHtmlExtension(),
        TagExtension(
          tagsToExtend: {'code'},
          builder: (context) {
            final code = context.element!.text;
            final codeBgColor =
                theme.colorScheme.secondaryContainer.withOpacity(0.25);
            if (code.contains('\n')) {
              return FadingScroll(
                builder: (context, controller) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: controller,
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: codeBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        code.trim(),
                        style: GoogleFonts.jetBrainsMono(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  );
                },
              );
            } else {
              return SelectableText(
                code.trim(),
                style: GoogleFonts.jetBrainsMono(
                  backgroundColor: codeBgColor,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              );
            }
          },
        ),
        TagExtension(
          tagsToExtend: {'h1'},
          builder: (context) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 5),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: theme.dividerColor),
                ),
              ),
              child: Text(
                context.element!.text,
                style: context.style!.generateTextStyle(),
              ),
            );
          },
        ),
        TagExtension(
          tagsToExtend: {'h2'},
          builder: (context) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 5),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: theme.dividerColor),
                ),
              ),
              child: Text(
                context.element!.text,
                style: context.style!.generateTextStyle(),
              ),
            );
          },
        ),
      ],
    );
  }
}
