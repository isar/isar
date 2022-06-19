import 'dart:math';

const String isarCoreVersion = '2.5.21'; //
final int isarCoreVersionNumber = _getVersionNumber(isarCoreVersion);

const String isarWebVersion = '2.5.1';

int _getVersionNumber(String version) {
  int number = 0;
  final List<String> components = isarCoreVersion.split('.');
  for (int i = 0; i < components.length; i++) {
    final String component = components[components.length - i - 1];
    number += (pow(100, i) * int.parse(component)).toInt();
  }
  return number;
}
