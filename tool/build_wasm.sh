rustup target add wasm32-unknown-unknown
npm install -g wasm-pack
wasm-pack build --target web --release packages/isar_core_ffi --features sqlite --no-default-features 
mv "packages/isar_core_ffi/pkg/isar_bg.wasm" "isar.wasm"