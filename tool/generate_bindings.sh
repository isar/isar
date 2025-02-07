#!/bin/sh

cargo install cbindgen

cbindgen --config tool/cbindgen.toml --crate isar --output packages/isar/isar-dart.h

cd packages/isar

dart pub get
dart run ffigen --config ffigen.yaml
dart run ffigen --config ffigen_web.yaml
rm isar-dart.h

dart tool/fix_web_bindings.dart

dart format lib/src/impl/bindings.dart
dart format lib/src/web/bindings.dart
