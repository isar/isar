import 'dart:math';

const isarCoreVersion = '2.5.24';
final isarCoreVersionNumber = _getVersionNumber(isarCoreVersion);

const isarWebVersion = '2.5.1';

int _getVersionNumber(String version) {
  var number = 0;
  final components = isarCoreVersion.split('.');
  for (var i = 0; i < components.length; i++) {
    final component = components[components.length - i - 1];
    number += (pow(100, i) * int.parse(component)).toInt();
  }
  return number;
}
