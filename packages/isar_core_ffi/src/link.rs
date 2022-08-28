use crate::txn::CIsarTxn;
use isar_core::collection::IsarCollection;
use isar_core::error::Result;
use itertools::Itertools;

#[no_mangle]
pub unsafe extern "C" fn isar_link(
    collection: &'static IsarCollection,
    txn: &mut CIsarTxn,
    link_id: u64,
    id: i64,
    target_id: i64,
) -> i64 {
    isar_try_txn!(txn, move |txn| -> Result<()> {
        collection.link(txn, link_id, id, target_id)?;
        Ok(())
    })
}

#[no_mangle]
pub unsafe extern "C" fn isar_link_unlink(
    collection: &'static IsarCollection,
    txn: &mut CIsarTxn,
    link_id: u64,
    id: i64,
    target_id: i64,
) -> i64 {
    isar_try_txn!(txn, move |txn| -> Result<()> {
        collection.unlink(txn, link_id, id, target_id)?;
        Ok(())
    })
}

#[no_mangle]
pub unsafe extern "C" fn isar_link_unlink_all(
    collection: &'static IsarCollection,
    txn: &mut CIsarTxn,
    link_id: u64,
    id: i64,
) -> i64 {
    isar_try_txn!(txn, move |txn| -> Result<()> {
        collection.unlink_all(txn, link_id, id)?;
        Ok(())
    })
}

#[no_mangle]
pub unsafe extern "C" fn isar_link_update_all(
    collection: &'static IsarCollection,
    txn: &mut CIsarTxn,
    link_id: u64,
    id: i64,
    ids: *const i64,
    link_count: u32,
    unlink_count: u32,
    replace: bool,
) -> i64 {
    let ids = std::slice::from_raw_parts(ids, (link_count + unlink_count) as usize);
    isar_try_txn!(txn, move |txn| {
        if replace {
            collection.unlink_all(txn, link_id, id)?;
        }
        for target_id in ids.iter().take(link_count as usize) {
            collection.link(txn, link_id, id, *target_id)?;
        }
        for target_id in ids
            .iter()
            .skip(link_count as usize)
            .take(unlink_count as usize)
        {
            collection.unlink(txn, link_id, id, *target_id)?;
        }
        Ok(())
    })
}

#[no_mangle]
pub unsafe extern "C" fn isar_link_verify(
    collection: &'static IsarCollection,
    txn: &mut CIsarTxn,
    link_id: u64,
    ids: *const i64,
    ids_count: u32,
) -> i64 {
    let ids = std::slice::from_raw_parts(ids, ids_count as usize);
    let links = ids.iter().copied().tuples().collect_vec();
    isar_try_txn!(txn, move |txn| -> Result<()> {
        collection.verify_link(txn, link_id, &links)?;
        Ok(())
    })
}
