rustup target add aarch64-apple-ios x86_64-apple-ios
cargo build --target aarch64-apple-ios --release
cargo build --target x86_64-apple-ios --release

lipo "target/aarch64-apple-ios/release/libisar.a" "target/x86_64-apple-ios/release/libisar.a" -output "libisar_ios.a" -create