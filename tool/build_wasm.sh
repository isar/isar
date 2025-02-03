rustup target add wasm32-unknown-unknown
wasm-pack build --target web --release packages/isar_core_ffi --features sqlite --no-default-features 
mv "packages/isar_core_ffi/pkg/isar_bg.wasm" "isar.wasm"