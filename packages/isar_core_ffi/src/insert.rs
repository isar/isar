use crate::{CIsarInsert, CIsarTxn};
use isar_core::core::insert::IsarInsert;
use std::ptr::null_mut;

#[no_mangle]
pub unsafe extern "C" fn isar_insert_save(insert: *mut *mut CIsarInsert<'static>, id: i64) -> u8 {
    isar_try! {
        let id = if id != i64::MIN {
            Some(id)
        } else {
            None
        };
        let old_insert = *Box::from_raw(*insert);
        insert.write(null_mut());
        let new_insert = match old_insert {
            CIsarInsert::Native(insert) => {
                let insert = insert.save(id)?;
                CIsarInsert::Native(insert)
            }
        };

        *insert = Box::into_raw(Box::new(new_insert));
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_insert_finish(
    insert: *mut CIsarInsert,
    txn: *mut *const CIsarTxn,
) -> u8 {
    isar_try! {
        let insert = *Box::from_raw(insert);
        let new_txn = match insert {
            CIsarInsert::Native(insert) => {
                let txn = insert.finish()?;
                CIsarTxn::Native(txn)
            }
        };
        *txn = Box::into_raw(Box::new(new_txn));
    }
}
