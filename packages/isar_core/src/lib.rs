#![allow(clippy::new_without_default)]

#[cfg(not(target_endian = "little"))]
compile_error!("Only little endian systems are supported.");

pub mod collection;
mod cursor;
pub mod error;
pub mod index;
pub mod instance;
mod legacy;
mod link;
mod mdbx;
pub mod object;
pub mod query;
pub mod schema;
pub mod txn;
pub mod watch;
