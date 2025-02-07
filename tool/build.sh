#!/bin/shuname

arch=$(uname -m)

if [ `uname` = "Linux" ] ;
then
    if [ $arch = "x86_64" ] ;
    then
        cargo build --target x86_64-unknown-linux-gnu --features sqlcipher-vendored --release
    else
        cargo build --target aarch64-unknown-linux-gnu --features sqlcipher-vendored  --release
    fi
elif [ `uname` = "Darwin" ] ;
then
     if [[ $arch == x86_64* ]]; then
        cargo build --target x86_64-apple-darwin --features sqlcipher  --release
    else
        cargo build --target aarch64-apple-darwin --features sqlcipher  --release
    fi
else
    cargo build --target x86_64-pc-windows-msvc --features sqlcipher-vendored  --release
fi