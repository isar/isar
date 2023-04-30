#![allow(clippy::new_without_default)]
#![feature(float_next_up_down)]

#[cfg(not(target_endian = "little"))]
compile_error!("Only little endian systems are supported.");

pub mod core;
pub mod filter;
pub mod native;
//pub mod sqlite;
mod util;
