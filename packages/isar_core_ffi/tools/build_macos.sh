rustup target add aarch64-apple-darwin x86_64-apple-darwin
cargo build -Z build-std=panic_abort,std --target aarch64-apple-darwin --release
cargo build -Z build-std=panic_abort,std --target x86_64-apple-darwin --release

lipo "target/aarch64-apple-darwin/release/libisar.dylib" "target/x86_64-apple-darwin/release/libisar.dylib" -output "libisar_macos.dylib" -create