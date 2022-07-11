import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

Future<void> download(List<dynamic> data, String fileName) async {
  if (data.isNotEmpty) {
    // Calling file selectors without isolate blocks main isolate (windows)
    await compute(_saveFile, {
      'fileName': fileName,
      'data': jsonEncode(data),
    });
  }
}

Future<void> _saveFile(Map<String, String> args) async {
  final result = await FilePicker.platform.saveFile(
    dialogTitle: 'Save file',
    fileName: args['fileName'],
  );

  if (result != null) {
    try {
      final file = File(result);
      await file.writeAsString(args['data']!);
    } catch (_) {}
  }
}
