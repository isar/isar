#!/bin/bash

core_version=`cat ../../CORE_VERSION`
github="https://github.com/isar/isar-core/releases/download/${core_version:5}"


curl "${github}/isar_windows_x64.dll" -o .dart_tool/isar_windows_x64.dll --create-dirs -L
curl "${github}/libisar_macos.dylib" -o .dart_tool/libisar_macos.dylib --create-dirs -L
curl "${github}/libisar_linux_x64.so" -o .dart_tool/libisar_linux_x64.so --create-dirs -L