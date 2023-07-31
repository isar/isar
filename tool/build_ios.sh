export IPHONEOS_DEPLOYMENT_TARGET=11.0

rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios
cargo build --target aarch64-apple-ios --features sqlcipher --release
cargo build --target aarch64-apple-ios-sim --features sqlcipher --release
cargo build --target x86_64-apple-ios --features sqlcipher --release

lipo "target/aarch64-apple-ios-sim/release/libisar.a" "target/x86_64-apple-ios/release/libisar.a" -output "target/aarch64-apple-ios-sim/libisar.a" -create
xcodebuild \
    -create-xcframework \
    -library target/aarch64-apple-ios/release/libisar.a \
    -library target/aarch64-apple-ios-sim/libisar.a \
    -output isar.xcframework 

zip -r isar_ios.xcframework.zip isar.xcframework