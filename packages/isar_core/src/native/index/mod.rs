use super::mdbx::db::Db;
use super::native_collection::NativeProperty;
use xxhash_rust::xxh3::xxh3_64;

pub mod id_key;
pub mod index_key;
pub(crate) mod index_key_builder;

#[derive(Clone, Eq, PartialEq)]
pub struct NativeIndex {
    pub name: String,
    pub id: u64,
    pub properties: Vec<NativeProperty>,
    pub unique: bool,
    pub multi_entry: bool,
    db: Db,
}

impl NativeIndex {
    pub(crate) const MAX_STRING_INDEX_SIZE: usize = 1024;

    pub fn new(name: &str, db: Db, properties: Vec<NativeProperty>, unique: bool) -> Self {
        let id = xxh3_64(name.as_bytes());
        let multi_entry = properties.first().unwrap().data_type.is_list();
        NativeIndex {
            name: name.to_string(),
            id,
            properties,
            unique,
            multi_entry,
            db,
        }
    }

    /*pub fn create_for_object<F>(
        &self,
        cursors: &IsarCursors,
        id: i64,
        object: IsarObject,
        mut delete: F,
    ) -> Result<()>
    where
        F: FnMut(i64) -> Result<()>,
    {
        let mut cursor = cursors.get_cursor(self.db)?;
        let key_builder = IndexKeyBuilder::new(&self.properties);
        key_builder.create_keys(object, |key| {
            if self.unique {
                let existing = cursor.move_to(key)?;
                if let Some((_, existing_id_bytes)) = existing {
                    let existing_id = existing_id_bytes.to_id();
                    if self.replace && existing_id != id {
                        delete(existing_id)?;
                    } else {
                        return Err(IsarError::UniqueViolated {});
                    }
                }
            }
            cursor.put(key, &id.to_id_bytes())?;
            Ok(true)
        })?;

        Ok(())
    }

    pub fn delete_for_object(
        &self,
        cursors: &IsarCursors,
        id: i64,
        object: IsarObject,
    ) -> Result<()> {
        let mut cursor = cursors.get_cursor(self.db)?;
        let key_builder = IndexKeyBuilder::new(&self.properties);
        key_builder.create_keys(object, |key| {
            let entry = if self.unique {
                cursor.move_to(key)?
            } else {
                cursor.move_to_key_val(key, &id.to_id_bytes())?
            };
            if entry.is_some() {
                cursor.delete_current()?;
            }
            Ok(true)
        })?;
        Ok(())
    }

    pub fn iter_between<'txn, 'env>(
        &self,
        cursors: &IsarCursors<'txn, 'env>,
        lower_key: &IndexKey,
        upper_key: &IndexKey,
        skip_duplicates: bool,
        ascending: bool,
        mut callback: impl FnMut(i64) -> Result<bool>,
    ) -> Result<bool> {
        let mut cursor = cursors.get_cursor(self.db)?;
        cursor.iter_between(
            lower_key,
            upper_key,
            !self.unique,
            skip_duplicates,
            ascending,
            |_, _, id_bytes| callback(id_bytes.to_id()),
        )
    }

    pub fn get_id<'txn, 'env>(
        &self,
        cursors: &IsarCursors<'txn, 'env>,
        key: &IndexKey,
    ) -> Result<Option<i64>> {
        let mut result = None;
        self.iter_between(cursors, key, key, false, true, |id| {
            result = Some(id);
            Ok(false)
        })?;
        Ok(result)
    }

    pub fn get_size(&self, cursors: &IsarCursors) -> Result<u64> {
        Ok(cursors.db_stat(self.db)?.1)
    }

    pub fn clear(&self, cursors: &IsarCursors) -> Result<()> {
        cursors.clear_db(self.db)
    }

    pub fn verify(&self, cursors: &IsarCursors, objects: &IntMap<IsarObject>) -> Result<()> {
        let mut count = 0;

        let mut cursor = cursors.get_cursor(self.db)?;
        for id in objects.keys() {
            let id = *id;
            let object = *objects.get(id).unwrap();
            let key_builder = IndexKeyBuilder::new(&self.properties);
            key_builder.create_keys(object, |key| {
                count += 1;

                let result = cursor.move_to_key_val(key, &(id as i64).to_id_bytes())?;
                if result.is_some() {
                    Ok(true)
                } else {
                    Err(IsarError::DbCorrupted {
                        message: "Missing index entry.".to_string(),
                    })
                }
            })?;
        }

        if cursors.db_stat(self.db)?.0 != count {
            Err(IsarError::DbCorrupted {
                message: "Obsolete index entry.".to_string(),
            })
        } else {
            Ok(())
        }
    }*/
}
