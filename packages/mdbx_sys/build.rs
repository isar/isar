use bindgen::callbacks::{IntKind, ParseCallbacks};
use std::process::Command;
use std::{env, fs, path::PathBuf};

#[derive(Debug)]
struct Callbacks;

impl ParseCallbacks for Callbacks {
    fn int_macro(&self, name: &str, _value: i64) -> Option<IntKind> {
        match name {
            "MDBX_SUCCESS"
            | "MDBX_KEYEXIST"
            | "MDBX_NOTFOUND"
            | "MDBX_PAGE_NOTFOUND"
            | "MDBX_CORRUPTED"
            | "MDBX_PANIC"
            | "MDBX_VERSION_MISMATCH"
            | "MDBX_INVALID"
            | "MDBX_MAP_FULL"
            | "MDBX_DBS_FULL"
            | "MDBX_READERS_FULL"
            | "MDBX_TLS_FULL"
            | "MDBX_TXN_FULL"
            | "MDBX_CURSOR_FULL"
            | "MDBX_PAGE_FULL"
            | "MDBX_MAP_RESIZED"
            | "MDBX_INCOMPATIBLE"
            | "MDBX_BAD_RSLOT"
            | "MDBX_BAD_TXN"
            | "MDBX_BAD_VALSIZE"
            | "MDBX_BAD_DBI"
            | "MDBX_LOG_DONTCHANGE"
            | "MDBX_DBG_DONTCHANGE"
            | "MDBX_RESULT_TRUE"
            | "MDBX_UNABLE_EXTEND_MAPSIZE"
            | "MDBX_PROBLEM"
            | "MDBX_LAST_LMDB_ERRCODE"
            | "MDBX_BUSY"
            | "MDBX_EMULTIVAL"
            | "MDBX_EBADSIGN"
            | "MDBX_WANNA_RECOVERY"
            | "MDBX_EKEYMISMATCH"
            | "MDBX_TOO_LARGE"
            | "MDBX_THREAD_MISMATCH"
            | "MDBX_TXN_OVERLAPPING"
            | "MDBX_LAST_ERRCODE" => Some(IntKind::Int),
            _ => Some(IntKind::UInt),
        }
    }
}

const LIBMDBX_VERSION: &str = "0.13.3";

fn main() {
    println!("cargo:rerun-if-changed=build.rs");
    env::set_var("IPHONEOS_DEPLOYMENT_TARGET", "12.0");
    env::set_var("RUST_BACKTRACE", "full");

    let _ = fs::remove_dir_all("libmdbx");
    fs::create_dir("libmdbx").unwrap();

    // download amalgamated source
    Command::new("curl")
        .arg("-O")
        .arg(format!(
            "https://libmdbx.dqdkfa.ru/release/libmdbx-amalgamated-{}.tar.xz",
            LIBMDBX_VERSION
        ))
        .current_dir("libmdbx")
        .output()
        .unwrap();

    // unzip file
    Command::new("tar")
        .arg("-xf")
        .arg(format!("libmdbx-amalgamated-{}.tar.xz", LIBMDBX_VERSION))
        .current_dir("libmdbx")
        .output()
        .unwrap();

    let mut mdbx = PathBuf::from(&env::var("CARGO_MANIFEST_DIR").unwrap());
    mdbx.push("libmdbx");

    let out_path = PathBuf::from(env::var("OUT_DIR").unwrap());

    let bindings = bindgen::Builder::default()
        .header(mdbx.join("mdbx.h").to_string_lossy())
        .allowlist_var("^(MDBX|mdbx)_.*")
        .allowlist_type("^(MDBX|mdbx)_.*")
        .allowlist_function("^(MDBX|mdbx)_.*")
        .rustified_enum("^(MDBX_option|MDBX_cursor_op)")
        .size_t_is_usize(false)
        .ctypes_prefix("std::ffi")
        .parse_callbacks(Box::new(Callbacks))
        .layout_tests(false)
        .prepend_enum_name(false)
        .generate_comments(true)
        .disable_header_comment()
        .generate()
        .expect("Unable to generate bindings");

    bindings
        .write_to_file(out_path.join("bindings.rs"))
        .expect("Couldn't write bindings!");

    let mut cc_builder = cc::Build::new();
    let flags = format!("{:?}", cc_builder.get_compiler().cflags_env());
    cc_builder.flag_if_supported("-Wno-everything");

    if cfg!(windows) {
        let dst = cmake::Config::new(&mdbx)
            .define("MDBX_INSTALL_STATIC", "1")
            .define("MDBX_BUILD_CXX", "0")
            .define("MDBX_BUILD_TOOLS", "0")
            .define("MDBX_BUILD_SHARED_LIBRARY", "0")
            .define("MDBX_LOCK_SUFFIX", "\".lock\"")
            .define("MDBX_TXN_CHECKOWNER", "0")
            .define("MDBX_WITHOUT_MSVC_CRT", "1")
            // Setting HAVE_LIBM=1 is necessary to override issues with `pow` detection on Windows
            .define("UNICODE", "1")
            .define("HAVE_LIBM", "1")
            .define("NDEBUG", "1")
            .cflag("/w")
            .init_c_cfg(cc_builder)
            .build();

        println!("cargo:rustc-link-lib=mdbx");
        println!(
            "cargo:rustc-link-search=native={}",
            dst.join("lib").display()
        );
        println!(r"cargo:rustc-link-lib=ntdll");
        println!(r"cargo:rustc-link-search=C:\windows\system32");
    } else {
        cc_builder
            .define("MDBX_BUILD_FLAGS", flags.as_str())
            .define("MDBX_BUILD_CXX", "0")
            .define("MDBX_BUILD_TOOLS", "0")
            .define("MDBX_BUILD_SHARED_LIBRARY", "0")
            .define("MDBX_LOCK_SUFFIX", "\".lock\"")
            .define("MDBX_TXN_CHECKOWNER", "0")
            .define("MDBX_APPLE_SPEED_INSTEADOF_DURABILITY", "1")
            .define("MDBX_HAVE_BUILTIN_CPU_SUPPORTS", "0")
            .define("NDEBUG", "1")
            .file(mdbx.join("mdbx.c"))
            .compile("libmdbx.a");
    }
}
