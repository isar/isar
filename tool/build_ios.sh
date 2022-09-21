rustup target add aarch64-apple-ios x86_64-apple-ios aarch64-apple-ios-sim

export IPHONEOS_DEPLOYMENT_TARGET=10.0

cargo build --target aarch64-apple-ios --release
cargo build --target x86_64-apple-ios --release
cargo build --target aarch64-apple-ios-sim --release

lipo "target/aarch64-apple-ios/release/libisar.a" "target/x86_64-apple-ios/release/libisar.a" -output "libisar_ios.a" -create
lipo "target/x86_64-apple-ios/release/libisar.a" "target/aarch64-apple-ios-sim/release/libisar.a" -output "libisar_ios_sim.a" -create
