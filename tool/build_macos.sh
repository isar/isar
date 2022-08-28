rustup target add aarch64-apple-darwin x86_64-apple-darwin
cargo build --target aarch64-apple-darwin --release
cargo build --target x86_64-apple-darwin --release

lipo "target/aarch64-apple-darwin/release/libisar.dylib" "target/x86_64-apple-darwin/release/libisar.dylib" -output "libisar_macos.dylib" -create