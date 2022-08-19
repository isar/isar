use crate::cursor::IsarCursors;
use crate::error::{IsarError, Result};
use crate::mdbx::cursor::Cursor;
use crate::mdbx::db::Db;
use crate::object::id::{BytesToId, IdToBytes};
use crate::object::isar_object::IsarObject;
use std::ops::Deref;
use xxhash_rust::xxh3::xxh3_64_with_seed;

#[derive(Clone)]
pub(crate) struct IsarLink {
    pub name: String,
    pub id: u64,
    db: Db,
    bl_db: Db,
    source_db: Db,
    target_db: Db,
}

impl IsarLink {
    pub fn new(
        collection: &str,
        name: &str,
        backlink: bool,
        db: Db,
        bl_db: Db,
        source_db: Db,
        target_db: Db,
    ) -> IsarLink {
        let seed = if backlink { 1 } else { 0 };
        let seed = xxh3_64_with_seed(collection.as_bytes(), seed);
        let id = xxh3_64_with_seed(name.as_bytes(), seed);
        IsarLink {
            name: name.to_string(),
            id,
            db,
            bl_db,
            source_db,
            target_db,
        }
    }

    pub fn iter_ids<F>(&self, cursors: &IsarCursors, id: i64, mut callback: F) -> Result<bool>
    where
        F: FnMut(&mut Cursor, i64) -> Result<bool>,
    {
        let mut cursor = cursors.get_cursor(self.db)?;
        cursor.iter_dups(&id, |cursor, link_target_key| {
            callback(cursor, link_target_key.to_id())
        })
    }

    pub fn iter<'txn, 'env, F>(
        &self,
        cursors: &IsarCursors<'txn, 'env>,
        id: i64,
        mut callback: F,
    ) -> Result<bool>
    where
        F: FnMut(i64, IsarObject<'txn>) -> Result<bool>,
    {
        let mut target_cursor = cursors.get_cursor(self.target_db)?;
        self.iter_ids(cursors, id, |_, link_target_key| {
            if let Some((id_bytes, object)) = target_cursor.move_to(&link_target_key)? {
                callback(id_bytes.deref().to_id(), IsarObject::from_bytes(&object))
            } else {
                Err(IsarError::DbCorrupted {
                    message: "Target object does not exist".to_string(),
                })
            }
        })
    }

    pub fn create(&self, cursors: &IsarCursors, source_id: i64, target_id: i64) -> Result<bool> {
        let mut source_cursor = cursors.get_cursor(self.source_db)?;
        let mut target_cursor = cursors.get_cursor(self.target_db)?;

        let exists_source = source_cursor.move_to(&source_id)?.is_some();
        let exists_target = target_cursor.move_to(&target_id)?.is_some();
        if !exists_source || !exists_target {
            return Ok(false);
        }

        let mut link_cursor = cursors.get_cursor(self.db)?;
        link_cursor.put(&source_id, &target_id.to_id_bytes())?;

        let mut backlink_cursor = cursors.get_cursor(self.bl_db)?;
        backlink_cursor.put(&target_id, &source_id.to_id_bytes())?;
        Ok(true)
    }

    pub fn delete(&self, cursors: &IsarCursors, source_id: i64, target_id: i64) -> Result<bool> {
        let mut link_cursor = cursors.get_cursor(self.db)?;
        let exists = link_cursor
            .move_to_key_val(&source_id, &target_id.to_id_bytes())?
            .is_some();

        if exists {
            let mut backlink_cursor = cursors.get_cursor(self.bl_db)?;
            let backlink_exists = backlink_cursor
                .move_to_key_val(&target_id, &source_id.to_id_bytes())?
                .is_some();
            if backlink_exists {
                link_cursor.delete_current()?;
                backlink_cursor.delete_current()?;
                Ok(true)
            } else {
                Err(IsarError::DbCorrupted {
                    message: "Backlink does not exist".to_string(),
                })
            }
        } else {
            Ok(false)
        }
    }

    pub fn delete_all_for_object(&self, cursors: &IsarCursors, id: i64) -> Result<()> {
        let id_bytes = id.to_id_bytes();

        let mut backlink_cursor = cursors.get_cursor(self.bl_db)?;
        self.iter_ids(cursors, id, |cursor, link_target_key| {
            let exists = backlink_cursor
                .move_to_key_val(&link_target_key, &id_bytes)?
                .is_some();
            if exists {
                cursor.delete_current()?;
                backlink_cursor.delete_current()?;
                Ok(true)
            } else {
                Err(IsarError::DbCorrupted {
                    message: "Backlink does not exist".to_string(),
                })
            }
        })?;
        Ok(())
    }

    pub fn get_size(&self, cursors: &IsarCursors) -> Result<u64> {
        Ok(cursors.db_stat(self.db)?.1)
    }

    pub fn clear(&self, cursors: &IsarCursors) -> Result<()> {
        cursors.clear_db(self.db)?;
        cursors.clear_db(self.bl_db)
    }

    pub fn verify(&self, cursors: &IsarCursors, links: &[(i64, i64)]) -> Result<()> {
        let link_count = cursors.db_stat(self.db)?.0 as usize;
        let backlink_count = cursors.db_stat(self.db)?.0 as usize;
        if link_count != links.len() || backlink_count != links.len() {
            return Err(IsarError::DbCorrupted {
                message: "Link or Backlink count mismatch.".to_string(),
            });
        }

        let mut cursor = cursors.get_cursor(self.db)?;
        cursor.iter_all(false, true, |_, id_bytes, target_id_bytes| {
            let id = id_bytes.to_id();
            let target_id = target_id_bytes.to_id();
            if links.contains(&(id, target_id)) {
                Ok(true)
            } else {
                Err(IsarError::DbCorrupted {
                    message: "Unknown link in database.".to_string(),
                })
            }
        })?;

        let mut cursor = cursors.get_cursor(self.bl_db)?;
        cursor.iter_all(false, true, |_, target_id_bytes, id_bytes| {
            let id = id_bytes.to_id();
            let target_id = target_id_bytes.to_id();
            if links.contains(&(id, target_id)) {
                Ok(true)
            } else {
                Err(IsarError::DbCorrupted {
                    message: "Unknown link in database.".to_string(),
                })
            }
        })?;

        Ok(())
    }
}
