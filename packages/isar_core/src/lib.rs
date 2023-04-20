#![allow(clippy::new_without_default)]

#[cfg(not(target_endian = "little"))]
compile_error!("Only little endian systems are supported.");

pub mod common;
pub mod core;
pub mod native;
pub mod sqlite;
