use std::sync::atomic::{self, AtomicI64};
use std::sync::Arc;

use super::sqlite_query::SQLiteQuery;
use super::sqlite_txn::SQLiteTxn;
use crate::core::data_type::DataType;
use crate::core::error::Result;
use crate::core::schema::IndexSchema;
use crate::core::watcher::CollectionWatchers;

#[derive(Debug)]
pub(crate) struct SQLiteProperty {
    pub name: String,
    pub data_type: DataType,
    // for embedded objects
    pub collection_index: Option<u16>,
}

impl SQLiteProperty {
    pub const ID_NAME: &str = "_rowid_";

    pub fn new(name: &str, data_type: DataType, collection_index: Option<u16>) -> Self {
        SQLiteProperty {
            name: name.to_string(),
            data_type,
            collection_index,
        }
    }
}

pub(crate) struct SQLiteCollection {
    pub name: String,
    pub id_name: Option<String>,
    pub properties: Vec<SQLiteProperty>,
    pub watchers: Arc<CollectionWatchers<SQLiteQuery>>,
    auto_increment: AtomicI64,

    // these are only used for verification
    pub indexes: Vec<IndexSchema>,
}

impl SQLiteCollection {
    pub fn new(
        name: String,
        id_name: Option<String>,
        properties: Vec<SQLiteProperty>,
        indexes: Vec<IndexSchema>,
    ) -> Self {
        Self {
            name,
            id_name,
            properties,
            watchers: CollectionWatchers::new(),
            auto_increment: AtomicI64::new(0),
            indexes,
        }
    }

    pub fn is_embedded(&self) -> bool {
        self.id_name.is_none()
    }

    pub fn init_auto_increment(&self, txn: &SQLiteTxn) -> Result<()> {
        let sqlite = txn.get_sqlite(false)?;

        let sql = format!("SELECT MAX(_rowid_) FROM {}", self.name);
        let mut stmt = sqlite.prepare(&sql)?;
        stmt.step()?;

        let next_id = stmt.get_long(0) + 1;
        self.auto_increment
            .store(next_id, atomic::Ordering::Release);

        Ok(())
    }

    pub fn auto_increment(&self) -> i64 {
        self.auto_increment.fetch_add(1, atomic::Ordering::AcqRel)
    }

    pub fn update_auto_increment(&self, id: i64) {
        self.auto_increment
            .fetch_max(id + 1, atomic::Ordering::AcqRel);
    }

    pub fn get_property(&self, property_index: u16) -> Option<&SQLiteProperty> {
        if property_index != 0 {
            self.properties.get(property_index as usize - 1)
        } else {
            None
        }
    }

    pub fn get_property_name(&self, property_index: u16) -> &str {
        if let Some(property) = self.get_property(property_index) {
            &property.name
        } else {
            SQLiteProperty::ID_NAME
        }
    }
}
