use super::native_collection::NativeCollection;
use super::native_txn::NativeTxn;
use crate::core::error::{IsarError, Result};

pub(crate) fn verify_native(txn: &NativeTxn, collections: &[NativeCollection]) -> Result<()> {
    let mut db_names = vec![];
    db_names.push("_info".to_string());
    for col in collections {
        if !col.is_embedded() {
            db_names.push(col.name.clone());
            for index in &col.indexes {
                db_names.push(format!("_{}_{}", col.name, index.name));
            }
        }
    }
    let mut actual_db_names = txn.db_names()?;

    db_names.sort();
    actual_db_names.sort();

    if db_names != actual_db_names {
        Err(IsarError::DbCorrupted {})
    } else {
        Ok(())
    }
}
