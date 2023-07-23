use std::{env, fs::File, io::Write, path::Path};

fn main() {
    let out_dir = env::var("OUT_DIR").unwrap();
    let dest_path = Path::new(&out_dir).join("version.rs");
    let mut f = File::create(&dest_path).unwrap();

    let version = option_env!("ISAR_VERSION");
    let version = version.map_or("debug", |version| {
        let version = if version.starts_with("v") {
            &version[1..]
        } else {
            version
        };
        version
    });

    write!(&mut f, "pub const ISAR_VERSION: &str = \"{version}\0\";").unwrap();
    println!("cargo:rerun-if-env-changed=ISAR_VERSION");

    let target_os = env::var("CARGO_CFG_TARGET_OS").expect("CARGO_CFG_TARGET_OS not set");
    let target_arch = env::var("CARGO_CFG_TARGET_ARCH").expect("CARGO_CFG_TARGET_ARCH not set");
    if target_arch == "x86_64" && target_os == "android" {
        let android_ndk_home = env::var("ANDROID_NDK_HOME").expect("ANDROID_NDK_HOME not set");
        println!("cargo:rustc-link-search={android_ndk_home}/toolchains/llvm/prebuilt/linux-x86_64/lib64/clang/14.0.7/lib/linux/");
        println!("cargo:rustc-link-search={android_ndk_home}/toolchains/llvm/prebuilt/darwin-x86_64/lib64/clang/14.0.7/lib/linux/");
        println!("cargo:rustc-link-lib=static=clang_rt.builtins-x86_64-android");
    }
}
