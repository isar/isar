#!/bin/bash

core_version=`cat ../CORE_VERSION`
github="https://github.com/isar/isar-core/releases/download/${core_version:5}"


curl "${github}/libisar_android.so" -o android/src/main/jniLibs/arm64-v8a/libisar.so --create-dirs
curl "${github}/libisar_androidx86.so" -o android/src/main/jniLibs/x86/libisar.so --create-dirs