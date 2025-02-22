rustup target add wasm32-unknown-unknown
cargo install wasm-opt
cargo build --target wasm32-unknown-unknown --features sqlite --no-default-features -p isar --release
wasm-opt -O4 target/wasm32-unknown-unknown/release/isar.wasm -o isar.wasm -all
