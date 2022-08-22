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

    write!(&mut f, "const ISAR_VERSION: &str = \"{version}\0\";").unwrap();
    println!("cargo:rerun-if-env-changed=ISAR_VERSION");
}
