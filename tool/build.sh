#!/bin/shuname

arch=$(uname -m)

if [ `uname` = "Linux" ] ;
then
    if [ $arch = "x86_64" ] ;
    then
        cargo build --target x86_64-unknown-linux-gnu --release
    else
        cargo build --target aarch64-unknown-linux-gnu --release
    fi
elif [ `uname` = "Darwin" ] ;
then
     if [[ $arch == x86_64* ]]; then
        cargo build --target x86_64-apple-darwin --release
    else
        cargo build --target aarch64-apple-darwin --release
    fi
else
    cargo build --target x86_64-pc-windows-msvc --release
fi