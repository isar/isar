#!/bin/sh

cargo install cbindgen

cbindgen --config tool/cbindgen.toml --crate isar --output packages/isar/isar-dart.h

cd packages/isar

dart pub get
dart run ffigen --config ffigen.yaml
rm isar-dart.h

dart format --fix lib/src/impl/bindings.dart
