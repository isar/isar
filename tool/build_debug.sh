arch=$(uname -m)

case "$OSTYPE" in
  darwin*)
    if [[ $arch == x86_64* ]]; then
        cargo build --target x86_64-apple-darwin
    else
        cargo build --target aarch64-apple-darwin
    fi
  ;; 
  linux*)
    if [[ $arch == x86_64* ]]; then
        cargo build --target x86_64-unknown-linux-gnu
    else
        cargo build --target aarch64-unknown-linux-gnu
    fi
  ;;
  *)
    cargo build --target x86_64-pc-windows-msvc
  ;;
esac