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
