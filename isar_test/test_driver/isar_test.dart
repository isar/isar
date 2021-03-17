// @dart = 2.8
// ignore: import_of_legacy_library_into_null_safe
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  test('Isar driver test', () async {
    final driver = await FlutterDriver.connect();
    final success =
        await driver.requestData(null, timeout: const Duration(minutes: 3));
    expect(success, 'true');
    await driver.close();
  });
}
