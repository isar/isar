use super::index_key::IndexKey;
use super::isar_deserializer::IsarDeserializer;
use super::mdbx::db::Db;
use super::native_collection::NativeProperty;
use super::native_txn::NativeTxn;
use super::{BytesToId, IdToBytes};
use crate::core::data_type::DataType;
use crate::core::error::Result;

#[derive(Clone, Eq, PartialEq)]
pub(crate) struct NativeIndex {
    pub name: String,
    pub properties: Vec<NativeProperty>,
    pub unique: bool,
    pub hash: bool,
    db: Db,
}

impl NativeIndex {
    pub fn new(
        name: &str,
        db: Db,
        properties: Vec<NativeProperty>,
        unique: bool,
        hash: bool,
    ) -> Self {
        NativeIndex {
            name: name.to_string(),
            properties,
            unique,
            hash,
            db,
        }
    }

    fn create_key(&self, object: IsarDeserializer, buffer: Vec<u8>) -> (Vec<u8>, bool) {
        let mut key = IndexKey::with_buffer(buffer);
        for property in &self.properties {
            match property.data_type {
                DataType::Bool => key.add_bool(object.read_bool(property.offset)),
                DataType::Byte => key.add_byte(object.read_byte(property.offset)),
                DataType::Int => key.add_int(object.read_int(property.offset)),
                DataType::Float => key.add_float(object.read_float(property.offset)),
                DataType::Long => key.add_long(object.read_long(property.offset)),
                DataType::Double => key.add_double(object.read_double(property.offset)),
                DataType::String => key.add_string(object.read_string(property.offset)),
                _ => unreachable!(),
            }
        }

        if self.hash {
            let hash = key.hash();
            let (mut buffer, contains_null) = key.finish();
            buffer.clear();
            buffer.extend_from_slice(&hash.to_be_bytes());
            (buffer, contains_null)
        } else {
            key.finish()
        }
    }

    pub fn create_for_object<F>(
        &self,
        txn: &NativeTxn,
        id: i64,
        object: IsarDeserializer,
        buffer: Vec<u8>,
        mut delete: F,
    ) -> Result<Vec<u8>>
    where
        F: FnMut(i64) -> Result<()>,
    {
        let mut cursor = txn.get_cursor(self.db)?;
        let (key, contains_null) = self.create_key(object, buffer);

        if self.unique && !contains_null {
            if let Some((_, id_bytes)) = cursor.move_to(&key)? {
                delete(id_bytes.to_id())?;
            }
        }
        cursor.put(&key, &id.to_id_bytes())?;

        Ok(key)
    }

    pub fn delete_for_object(
        &self,
        txn: &NativeTxn,
        id: i64,
        object: IsarDeserializer,
        buffer: Vec<u8>,
    ) -> Result<Vec<u8>> {
        let mut cursor = txn.get_cursor(self.db)?;
        let key = self.create_key(object, buffer).0;
        if cursor.move_to_key_val(&key, &id.to_id_bytes())?.is_some() {
            cursor.delete_current()?;
        }
        Ok(key)
    }

    pub fn get_size(&self, txn: &NativeTxn) -> Result<u64> {
        Ok(txn.stat(self.db)?.1)
    }

    pub fn clear(&self, txn: &NativeTxn) -> Result<()> {
        txn.clear_db(self.db)
    }

    /* pub fn iter_between<'txn, 'env>(
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
