use crate::{isar_to_i64, CIsarInstance, CIsarTxn, CIsarWriter, IsarI64};
use isar_core::core::error::IsarError;
use isar_core::core::insert::IsarInsert;
use isar_core::core::instance::IsarInstance;

#[no_mangle]
pub unsafe extern "C" fn isar_insert(
    isar: &'static CIsarInstance,
    txn: *mut CIsarTxn,
    collection_index: u16,
    count: u32,
    insert: *mut *const CIsarWriter,
) -> u8 {
    isar_try! {
        let txn = *Box::from_raw(txn);
        let new_insert = match (isar, txn) {
            #[cfg(feature = "native")]
            (CIsarInstance::Native(isar), CIsarTxn::Native(txn)) => {
                let insert = isar.insert(txn, collection_index, count)?;
                CIsarWriter::Native(insert)
            }
            #[cfg(feature = "sqlite")]
            (CIsarInstance::SQLite(isar), CIsarTxn::SQLite(txn)) => {
                let insert = isar.insert(txn, collection_index, count)?;
                CIsarWriter::SQLite(insert)
            }
            _ => return Err(IsarError::IllegalArgument {}),
        };
        *insert = Box::into_raw(Box::new(new_insert));
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_insert_save(insert: &mut CIsarWriter<'static>, id: IsarI64) -> u8 {
    let id = isar_to_i64(id);
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

#[no_mangle]
pub unsafe extern "C" fn isar_insert_abort(insert: *mut CIsarWriter) {
    let _ = *Box::from_raw(insert);
}
