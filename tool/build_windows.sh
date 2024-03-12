if [ "$1" = "x64" ]; then
  export PATH=/c/mingw64/bin:$PATH # Some bastard installer removes this from path during preparation
  rustup target add x86_64-pc-windows-msvc
  cargo build --target x86_64-pc-windows-msvc --features sqlcipher-vendored --release
  mv "target/x86_64-pc-windows-msvc/release/isar.dll" "isar_windows_x64.dll"
else
  rustup target add aarch64-pc-windows-msvc
  cargo build --target aarch64-pc-windows-msvc --features sqlcipher-vendored --release
  mv "target/aarch64-pc-windows-msvc/release/isar.dll" "isar_windows_arm64.dll"
fi