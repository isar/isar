rustup target add aarch64-apple-ios x86_64-apple-ios
cargo build -Z build-std=panic_abort,std --target aarch64-apple-ios --release
cargo build -Z build-std=panic_abort,std --target x86_64-apple-ios --release

lipo "target/aarch64-apple-ios/release/libisar.a" "target/x86_64-apple-ios/release/libisar.a" -output "libisar_ios.a" -create