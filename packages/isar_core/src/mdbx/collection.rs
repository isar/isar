use crate::cursor::IsarCursors;
use crate::error::{illegal_arg, IsarError, Result};
use crate::index::index_key::IndexKey;
use crate::index::index_key_builder::IndexKeyBuilder;
use crate::index::IsarIndex;
use crate::link::IsarLink;
use crate::mdbx::db::Db;
use crate::object::id::BytesToId;
use crate::object::isar_object::IsarObject;
use crate::object::json_encode_decode::JsonEncodeDecode;
use crate::object::object_builder::ObjectBuilder;
use crate::object::property::Property;
use crate::query::query_builder::QueryBuilder;
use crate::txn::IsarTxn;
use crate::watch::change_set::ChangeSet;
use intmap::IntMap;
use itertools::Itertools;
use serde_json::Value;
use std::cell::Cell;
use std::ops::Deref;
use xxhash_rust::xxh3::xxh3_64;

pub struct IsarCollection {
    pub name: String,
    pub id: u64,

    pub properties: Vec<Property>,
    pub embedded_properties: IntMap<Vec<Property>>,

    pub(crate) instance_id: u64,
    pub(crate) db: Db,

    pub(crate) indexes: Vec<IsarIndex>,
    pub(crate) links: Vec<IsarLink>, // links from this collection
    backlinks: Vec<IsarLink>,        // links to this collection

    auto_increment: Cell<i64>,
}

unsafe impl Send for IsarCollection {}
unsafe impl Sync for IsarCollection {}

impl IsarCollection {
    #[allow(clippy::too_many_arguments)]
    pub(crate) fn new(
        db: Db,
        instance_id: u64,
        name: &str,
        properties: Vec<Property>,
        embedded_properties: IntMap<Vec<Property>>,
        indexes: Vec<IsarIndex>,
        links: Vec<IsarLink>,
        backlinks: Vec<IsarLink>,
    ) -> Self {
        let id = xxh3_64(name.as_bytes());
        IsarCollection {
            name: name.to_string(),
            id,
            properties,
            embedded_properties,
            instance_id,
            db,
            indexes,
            links,
            backlinks,
            auto_increment: Cell::new(0),
        }
    }

    pub fn new_object_builder(&self, buffer: Option<Vec<u8>>) -> ObjectBuilder {
        ObjectBuilder::new(&self.properties, buffer)
    }

    pub fn new_query_builder(&self) -> QueryBuilder {
        QueryBuilder::new(self)
    }

    pub(crate) fn init_auto_increment(&self, cursors: &IsarCursors) -> Result<()> {
        let mut cursor = cursors.get_cursor(self.db)?;
        if let Some((key, _)) = cursor.move_to_last()? {
            let id = key.deref().to_id();
            self.update_auto_increment(id);
        }
        Ok(())
    }

    pub(crate) fn update_auto_increment(&self, id: i64) {
        if id > self.auto_increment.get() {
            self.auto_increment.set(id);
        }
    }

    pub fn auto_increment(&self, _: &mut IsarTxn) -> Result<i64> {
        self.auto_increment_internal()
    }

    pub(crate) fn auto_increment_internal(&self) -> Result<i64> {
        let last = self.auto_increment.get();
        if last < i64::MAX {
            self.auto_increment.set(last + 1);
            Ok(last + 1)
        } else {
            Err(IsarError::AutoIncrementOverflow {})
        }
    }

    pub fn get<'txn>(&self, txn: &'txn mut IsarTxn, id: i64) -> Result<Option<IsarObject<'txn>>> {
        txn.read(self.instance_id, |cursors| {
            let mut cursor = cursors.get_cursor(self.db)?;
            let object = cursor
                .move_to(&id)?
                .map(|(_, v)| IsarObject::from_bytes(&v));
            Ok(object)
        })
    }

    pub(crate) fn get_index_by_id(&self, index_id: u64) -> Result<&IsarIndex> {
        self.indexes
            .iter()
            .find(|i| i.id == index_id)
            .ok_or(IsarError::UnknownIndex {})
    }

    pub fn get_by_index<'txn>(
        &self,
        txn: &'txn mut IsarTxn,
        index_id: u64,
        key: &IndexKey,
    ) -> Result<Option<(i64, IsarObject<'txn>)>> {
        let index = self.get_index_by_id(index_id)?;
        txn.read(self.instance_id, |cursors| {
            if let Some(id) = index.get_id(cursors, key)? {
                let mut cursor = cursors.get_cursor(self.db)?;
                let (_, bytes) = cursor.move_to(&id)?.ok_or(IsarError::DbCorrupted {
                    message: "Invalid index entry".to_string(),
                })?;
                let result = (id, IsarObject::from_bytes(&bytes));
                Ok(Some(result))
            } else {
                Ok(None)
            }
        })
    }

    pub fn put(&self, txn: &mut IsarTxn, id: Option<i64>, object: IsarObject) -> Result<i64> {
        txn.write(self.instance_id, |cursors, change_set| {
            self.put_internal(cursors, change_set, id, object)
        })
    }

    pub fn put_by_index(
        &self,
        txn: &mut IsarTxn,
        index_id: u64,
        object: IsarObject,
    ) -> Result<i64> {
        let index = self.get_index_by_id(index_id)?;
        if index.multi_entry {
            illegal_arg("Cannot put by a multi-entry index")?;
        }
        let key_builder = IndexKeyBuilder::new(&index.properties);
        txn.write(self.instance_id, |cursors, change_set| {
            let key = key_builder.create_primitive_key(object);
            let id = index.get_id(cursors, &key)?;
            let new_id = self.put_internal(cursors, change_set, id, object)?;
            Ok(new_id)
        })
    }

    fn put_internal(
        &self,
        cursors: &IsarCursors,
        mut change_set: Option<&mut ChangeSet>,
        id: Option<i64>,
        object: IsarObject,
    ) -> Result<i64> {
        if object.len() > IsarObject::MAX_SIZE as usize {
            illegal_arg("Object is bigger than 16MB")?;
        }

        let id = if let Some(id) = id {
            self.delete_internal(cursors, false, change_set.as_deref_mut(), id)?;
            self.update_auto_increment(id);
            id
        } else {
            self.auto_increment_internal()?
        };

        for index in &self.indexes {
            index.create_for_object(cursors, id, object, |id| {
                self.delete_internal(cursors, true, change_set.as_deref_mut(), id)?;
                Ok(())
            })?;
        }

        let mut cursor = cursors.get_cursor(self.db)?;
        cursor.put(&id, object.as_bytes())?;
        if let Some(change_set) = change_set {
            change_set.register_change(self.id, id, object);
        }
        Ok(id)
    }

    pub fn delete(&self, txn: &mut IsarTxn, id: i64) -> Result<bool> {
        txn.write(self.instance_id, |cursors, change_set| {
            self.delete_internal(cursors, true, change_set, id)
        })
    }

    pub fn delete_by_index(
        &self,
        txn: &mut IsarTxn,
        index_id: u64,
        key: &IndexKey,
    ) -> Result<bool> {
        let index = self.get_index_by_id(index_id)?;
        txn.write(self.instance_id, |cursors, change_set| {
            if let Some(id) = index.get_id(cursors, key)? {
                self.delete_internal(cursors, true, change_set, id)?;
                Ok(true)
            } else {
                Ok(false)
            }
        })
    }

    fn delete_internal(
        &self,
        cursors: &IsarCursors,
        delete_links: bool,
        change_set: Option<&mut ChangeSet>,
        id: i64,
    ) -> Result<bool> {
        let mut cursor = cursors.get_cursor(self.db)?;
        if let Some((_, object)) = cursor.move_to(&id)? {
            let object = IsarObject::from_bytes(&object);
            for index in &self.indexes {
                index.delete_for_object(cursors, id, object)?;
            }
            if delete_links {
                for link in &self.links {
                    link.delete_all_for_object(cursors, id)?;
                }
                for link in &self.backlinks {
                    link.delete_all_for_object(cursors, id)?;
                }
            }
            if let Some(change_set) = change_set {
                change_set.register_change(self.id, id, object);
            }
            cursor.delete_current()?;
            Ok(true)
        } else {
            Ok(false)
        }
    }

    pub(crate) fn get_link_backlink(&self, link_id: u64) -> Result<&IsarLink> {
        if let Some(link) = self.links.iter().find(|l| l.id == link_id) {
            Ok(link)
        } else if let Some(link) = self.backlinks.iter().find(|l| l.id == link_id) {
            Ok(link)
        } else {
            illegal_arg("IsarLink does not exist")
        }
    }

    pub fn link(&self, txn: &mut IsarTxn, link_id: u64, id: i64, target_id: i64) -> Result<bool> {
        let link = self.get_link_backlink(link_id)?;
        txn.write(self.instance_id, |cursors, _| {
            link.create(cursors, id, target_id)
        })
    }

    pub fn unlink(&self, txn: &mut IsarTxn, link_id: u64, id: i64, target_id: i64) -> Result<bool> {
        let link = self.get_link_backlink(link_id)?;
        txn.write(self.instance_id, |cursors, _| {
            link.delete(cursors, id, target_id)
        })
    }

    pub fn unlink_all(&self, txn: &mut IsarTxn, link_id: u64, id: i64) -> Result<()> {
        let link = self.get_link_backlink(link_id)?;
        txn.write(self.instance_id, |cursors, _| {
            link.delete_all_for_object(cursors, id)
        })
    }

    pub fn clear(&self, txn: &mut IsarTxn) -> Result<()> {
        txn.write(self.instance_id, |cursors, change_set| {
            for index in &self.indexes {
                index.clear(cursors)?;
            }
            for link in &self.links {
                link.clear(cursors)?;
            }
            for link in &self.backlinks {
                link.clear(cursors)?;
            }
            cursors.clear_db(self.db)?;
            self.auto_increment.set(0);

            if let Some(change_set) = change_set {
                change_set.register_all(self.id);
            }

            Ok(())
        })
    }

    pub fn count(&self, txn: &mut IsarTxn) -> Result<u64> {
        txn.read(self.instance_id, |cursors| Ok(cursors.db_stat(self.db)?.0))
    }

    pub fn get_size(
        &self,
        txn: &mut IsarTxn,
        include_indexes: bool,
        include_links: bool,
    ) -> Result<u64> {
        txn.read(self.instance_id, |cursors| {
            let mut size = cursors.db_stat(self.db)?.1;

            if include_indexes {
                for index in &self.indexes {
                    size += index.get_size(cursors)?;
                }
            }

            if include_links {
                for link in &self.links {
                    size += link.get_size(cursors)?;
                }
            }

            Ok(size)
        })
    }

    pub fn import_json(&self, txn: &mut IsarTxn, id_name: Option<&str>, json: Value) -> Result<()> {
        txn.write(self.instance_id, |cursors, mut change_set| {
            let array = json.as_array().ok_or(IsarError::InvalidJson {})?;
            let mut ob_result_cache = None;
            for value in array {
                let id = if let Some(id_name) = id_name {
                    if let Some(id) = value.get(id_name) {
                        let id = id.as_i64().ok_or(IsarError::InvalidJson {})?;
                        Some(id)
                    } else {
                        None
                    }
                } else {
                    None
                };

                let mut ob = ObjectBuilder::new(&self.properties, ob_result_cache);
                JsonEncodeDecode::decode(
                    &self.properties,
                    &self.embedded_properties,
                    &mut ob,
                    value,
                )?;
                let object = ob.finish();
                self.put_internal(cursors, change_set.as_deref_mut(), id, object)?;
                ob_result_cache = Some(ob.recycle());
            }
            Ok(())
        })
    }

    pub(crate) fn fill_indexes(&self, index_ids: &[u64], cursors: &IsarCursors) -> Result<()> {
        let indexes = index_ids
            .iter()
            .map(|id| self.get_index_by_id(*id).unwrap())
            .collect_vec();

        let mut cursor = cursors.get_cursor(self.db)?;
        cursor.iter_all(false, true, |cursor, id_bytes, object| {
            let id = id_bytes.to_id();

            // The object might become invalid if another one is deleted by an index. TODO: Find a better solution
            let bytes = object.to_vec();
            let object = IsarObject::from_bytes(&bytes);

            for index in &indexes {
                index.create_for_object(cursors, id, object, |id| {
                    let deleted = self.delete_internal(cursors, true, None, id)?;
                    if deleted {
                        cursor.move_to_next()?;
                    }
                    Ok(())
                })?;
            }
            Ok(true)
        })?;
        Ok(())
    }

    pub fn verify(&self, txn: &mut IsarTxn, objects: &IntMap<IsarObject>) -> Result<()> {
        txn.read(self.instance_id, |cursors| {
            let mut counter = 0;
            let mut cursor = cursors.get_cursor(self.db)?;
            cursor.iter_all(false, true, |_, id_bytes, bytes| {
                let id = id_bytes.to_id();
                let db_object = IsarObject::from_bytes(bytes);
                let db_json = JsonEncodeDecode::encode(
                    &self.properties,
                    &self.embedded_properties,
                    db_object,
                    false,
                );
                if let Some(object) = objects.get(id as u64) {
                    let json = JsonEncodeDecode::encode(
                        &self.properties,
                        &self.embedded_properties,
                        *object,
                        false,
                    );
                    if json == db_json {
                        counter += 1;
                        return Ok(true);
                    }
                }
                Err(IsarError::DbCorrupted {
                    message: "Unknown object in database.".to_string(),
                })
            })?;

            if counter != objects.len() {
                return Err(IsarError::DbCorrupted {
                    message: "Object missing in database.".to_string(),
                });
            }

            for index in &self.indexes {
                index.verify(cursors, objects)?;
            }

            Ok(())
        })
    }

    pub fn verify_link(&self, txn: &mut IsarTxn, link_id: u64, links: &[(i64, i64)]) -> Result<()> {
        let link = self.get_link_backlink(link_id)?;
        txn.read(self.instance_id, |cursors| link.verify(cursors, links))
    }
}
