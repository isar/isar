#!/bin/bash

if [ -z "$ISAR_VERSION" ]; then
    echo "ISAR_VERSION is not set";
    exit 2;
fi

github="https://github.com/isar/isar/releases/download/$ISAR_VERSION"


curl "${github}/libisar_android_arm64.so" -o packages/isar_flutter_libs/android/src/main/jniLibs/arm64-v8a/libisar.so --create-dirs -L -f
curl "${github}/libisar_android_armv7.so" -o packages/isar_flutter_libs/android/src/main/jniLibs/armeabi-v7a/libisar.so --create-dirs -L -f
curl "${github}/libisar_android_x64.so" -o packages/isar_flutter_libs/android/src/main/jniLibs/x86_64/libisar.so --create-dirs -L

curl "${github}/isar_ios.xcframework.zip" -o packages/isar_flutter_libs/ios/isar_ios.xcframework.zip --create-dirs -L -f
unzip -o packages/isar_flutter_libs/ios/isar_ios.xcframework.zip -d packages/isar_flutter_libs/ios
rm packages/isar_flutter_libs/ios/isar_ios.xcframework.zip

curl "${github}/libisar_macos.dylib" -o packages/isar_flutter_libs/macos/libisar.dylib --create-dirs -L -f
curl "${github}/libisar_linux_x64.so" -o packages/isar_flutter_libs/linux/libisar.so --create-dirs -L -f
curl "${github}/isar_windows_x64.dll" -o packages/isar_flutter_libs/windows/isar.dll --create-dirs -L -f

curl "${github}/isar.wasm" -o isar.wasm -L -f