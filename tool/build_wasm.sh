rustup target add wasm32-unknown-unknown
cargo install wasm-opt
cargo build --target wasm32-unknown-unknown --features sqlite --no-default-features -p isar --release
wasm-opt -O4 --enable-bulk-memory --enable-nontrapping-float-to-int target/wasm32-unknown-unknown/release/isar.wasm -o isar.wasm
