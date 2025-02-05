rustup target add wasm32-unknown-unknown
cargo install wasm-opt
cargo build --target wasm32-unknown-unknown --features sqlite --no-default-features -p isar
mv target/wasm32-unknown-unknown/debug/isar.wasm isar.wasm