use std::{env, fs::File, io::Write, path::Path};

fn main() {
    let out_dir = env::var("OUT_DIR").unwrap();
    let dest_path = Path::new(&out_dir).join("version.rs");
    let mut f = File::create(&dest_path).unwrap();

    let version = option_env!("ISAR_VERSION");
    let version = version.map_or(0, |version| {
        let version = if version.starts_with("v") {
            &version[1..]
        } else {
            version
        };
        let components: Vec<u8> = version
            .split(".")
            .map(|v| str::parse::<u8>(v).unwrap())
            .collect();

        let mut version = 0;
        for (i, v) in components.iter().rev().enumerate() {
            version += 100usize.pow(i as u32) * (*v as usize);
        }
        version
    });

    write!(&mut f, "const ISAR_VERSION: usize = {};", version).unwrap();
    println!("cargo:rerun-if-env-changed=ISAR_VERSION");
}
