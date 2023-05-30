use crate::{CIsarTxn, CIsarWriter};
use isar_core::core::{error::IsarError, insert::IsarInsert};

#[no_mangle]
pub unsafe extern "C" fn isar_insert_save(insert: &mut CIsarWriter<'static>, id: i64) -> u8 {
    isar_try! {
        match insert {
            #[cfg(feature = "native")]
            CIsarWriter::Native(insert) => insert.save(id)?,
            #[cfg(feature = "sqlite")]
            CIsarWriter::SQLite(insert) => insert.save(id)?,
            _ => return Err(IsarError::IllegalArgument {}),
        };
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_insert_finish(
    insert: *mut CIsarWriter,
    txn: *mut *const CIsarTxn,
) -> u8 {
    isar_try! {
        let insert = *Box::from_raw(insert);
        let new_txn = match insert {
            #[cfg(feature = "native")]
            CIsarWriter::Native(insert) => CIsarTxn::Native(insert.finish()?),
            #[cfg(feature = "sqlite")]
            CIsarWriter::SQLite(insert) => CIsarTxn::SQLite(insert.finish()?),
            _ => return Err(IsarError::IllegalArgument {}),
        };
        *txn = Box::into_raw(Box::new(new_txn));
    }
}
