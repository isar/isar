// ignore_for_file: unused_field, public_member_api_docs

import 'dart:async';

import 'package:isar/isar.dart';
import 'package:meta/meta.dart';

/// @nodoc
@protected
const Id isarMinId = -9007199254740990;

/// @nodoc
@protected
const Id isarMaxId = 9007199254740991;

/// @nodoc
@protected
const Id isarAutoIncrementId = -9007199254740991;

/// @nodoc
Never unsupportedOnWeb() {
  throw UnsupportedError('This operation is not supported for Isar web');
}

class _WebAbi {
  static const androidArm = null as dynamic;
  static const androidArm64 = null as dynamic;
  static const androidIA32 = null as dynamic;
  static const androidX64 = null as dynamic;
  static const iosArm64 = null as dynamic;
  static const iosX64 = null as dynamic;
  static const linuxArm64 = null as dynamic;
  static const linuxX64 = null as dynamic;
  static const macosArm64 = null as dynamic;
  static const macosX64 = null as dynamic;
  static const windowsArm64 = null as dynamic;
  static const windowsX64 = null as dynamic;
}

/// @nodoc
@protected
typedef IsarAbi = _WebAbi;

FutureOr<void> initializeCoreBinary({
  Map<IsarAbi, String> libraries = const {},
  bool download = false,
}) =>
    unsupportedOnWeb();
