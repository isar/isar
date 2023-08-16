#![allow(clippy::new_without_default)]
#![feature(float_next_up_down)]
#![feature(return_position_impl_trait_in_trait)]
#![feature(lazy_cell)]

#[cfg(not(target_endian = "little"))]
compile_error!("Only little endian systems are supported.");

pub mod core;

pub const SQLITE_MEMORY_DIR: &str = ":memory:";

#[cfg(feature = "native")]
pub mod native;

#[cfg(feature = "sqlite")]
pub mod sqlite;
