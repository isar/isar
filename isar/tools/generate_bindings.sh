#!/bin/sh

script=$(readlink -f "$0")
script_dir=$(dirname "$script")

tmp_dir=$(mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir')
core_version=`cat ../CORE_VERSION`

cd $tmp_dir

git clone https://github.com/isar/isar-core.git
cd isar-core
git checkout $core_version
git submodule update --init

cargo install cbindgen
cbindgen --config $script_dir/cbindgen.toml --crate isar-core --output $script_dir/../isar-dart.h

cd $script_dir/../

dart pub get
dart pub run ffigen --config tools/ffigen.yaml
rm isar-dart.h

dart tools/fix_bindings.dart
dart format --fix lib/src/native/bindings.dart