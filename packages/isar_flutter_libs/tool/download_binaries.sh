#!/bin/bash

core_version=`cat ../CORE_VERSION`
github="https://github.com/isar/isar-core/releases/download/${core_version:5}"


curl "${github}/libisar_android_arm64.so" -o android/src/main/jniLibs/arm64-v8a/libisar.so --create-dirs -L
curl "${github}/libisar_android_x64.so" -o android/src/main/jniLibs/x86_64/libisar.so --create-dirs -L
curl "${github}/libisar_ios.a" -o ios/libisar.a --create-dirs -L
curl "${github}/libisar_macos_x64.dylib" -o macos/libisar.dylib --create-dirs -L