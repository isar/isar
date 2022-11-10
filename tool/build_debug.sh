arch=$(uname -m)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if [[ $arch == x86_64* ]]; then
        cargo build --target x86_64-unknown-linux-gnu
    else
        cargo build --target aarch64-unknown-linux-gnu
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    if [[ $arch == x86_64* ]]; then
        cargo build --target x86_64-apple-darwin
    else
        cargo build --target aarch64-apple-darwin
    fi
else
    cargo build --target x86_64-pc-windows-msvc
fi