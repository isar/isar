use crate::{
    core::query::IsarQuery,
    watch::watcher::{Watcher, WatcherCallback},
};
use crossbeam_channel::Receiver;
use intmap::IntMap;
use itertools::Itertools;
use std::sync::Arc;

pub(crate) type WatcherModifier<Q> = Box<dyn FnOnce(&mut IsarWatchers<Q>) + Send + 'static>;

pub(crate) struct IsarWatchers<Q: IsarQuery> {
    modifiers: Receiver<WatcherModifier<Q>>,
    collection_watchers: IntMap<IsarCollectionWatchers<Q>>,
}

impl<Q: IsarQuery> IsarWatchers<Q> {
    pub fn new(modifiers: Receiver<WatcherModifier<Q>>) -> Self {
        IsarWatchers {
            modifiers,
            collection_watchers: IntMap::new(),
        }
    }

    pub(crate) fn get_col_watchers(&mut self, col_id: u64) -> &mut IsarCollectionWatchers<Q> {
        if !self.collection_watchers.contains_key(col_id) {
            self.collection_watchers
                .insert(col_id, IsarCollectionWatchers::new());
        }
        self.collection_watchers.get_mut(col_id).unwrap()
    }

    pub(crate) fn sync(&mut self) {
        let modifiers = self.modifiers.try_iter().collect_vec();
        for modifier in modifiers {
            modifier(self)
        }
    }
}

pub struct IsarCollectionWatchers<Q: IsarQuery> {
    pub(super) watchers: Vec<Arc<Watcher>>,
    pub(super) object_watchers: IntMap<Vec<Arc<Watcher>>>,
    pub(super) query_watchers: Vec<(Q, Arc<Watcher>)>,
}

impl<Q: IsarQuery> IsarCollectionWatchers<Q> {
    fn new() -> Self {
        IsarCollectionWatchers {
            watchers: Vec::new(),
            object_watchers: IntMap::new(),
            query_watchers: Vec::new(),
        }
    }

    pub fn add_watcher(&mut self, watcher_id: u64, callback: WatcherCallback) {
        let watcher = Arc::new(Watcher::new(watcher_id, callback));
        self.watchers.push(watcher);
    }

    pub fn remove_watcher(&mut self, watcher_id: u64) {
        let position = self
            .watchers
            .iter()
            .position(|w| w.get_id() == watcher_id)
            .unwrap();
        self.watchers.remove(position);
    }

    pub fn add_object_watcher(&mut self, watcher_id: u64, id: i64, callback: WatcherCallback) {
        let watcher = Arc::new(Watcher::new(watcher_id, callback));
        if let Some(object_watchers) = self.object_watchers.get_mut(id as u64) {
            object_watchers.push(watcher);
        } else {
            self.object_watchers.insert(id as u64, vec![watcher]);
        }
    }

    pub fn remove_object_watcher(&mut self, id: i64, watcher_id: u64) {
        let watchers = self.object_watchers.get_mut(id as u64).unwrap();
        let position = watchers
            .iter()
            .position(|w| w.get_id() == watcher_id)
            .unwrap();
        watchers.remove(position);
    }

    pub fn add_query_watcher(&mut self, watcher_id: u64, query: Q, callback: WatcherCallback) {
        let watcher = Arc::new(Watcher::new(watcher_id, callback));
        self.query_watchers.push((query, watcher));
    }

    pub fn remove_query_watcher(&mut self, watcher_id: u64) {
        let position = self
            .query_watchers
            .iter()
            .position(|(_, w)| w.get_id() == watcher_id)
            .unwrap();
        self.query_watchers.remove(position);
    }
}
