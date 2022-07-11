import 'dart:convert';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html';

Future<void> download(List<dynamic> data, String fileName) async {
  if (data.isEmpty) {
    return;
  }

  try {
    final base64 = base64Encode(utf8.encode(jsonEncode(data)));
    final anchor =
        AnchorElement(href: 'data:application/octet-stream;base64,$base64')
          ..target = 'blank'
          ..download = fileName;

    document.body!.append(anchor);
    anchor.click();
    anchor.remove();
  } catch (_) {}
}
