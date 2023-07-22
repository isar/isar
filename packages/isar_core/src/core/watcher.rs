use intmap::IntMap;
use parking_lot::RwLock;
use std::sync::{
    atomic::{AtomicU64, Ordering},
    Arc,
};

static WATCHER_ID: AtomicU64 = AtomicU64::new(0);

pub type WatcherCallback = Box<dyn Fn() + Send + Sync + 'static>;

struct Watcher {
    id: u64,
    callback: WatcherCallback,
}

impl Watcher {
    pub fn new(callback: WatcherCallback) -> Self {
        Watcher {
            id: WATCHER_ID.fetch_add(1, Ordering::SeqCst),
            callback,
        }
    }

    pub fn get_id(&self) -> u64 {
        self.id
    }

    pub fn notify(&self) {
        (*self.callback)()
    }
}

pub struct WatchHandle {
    stop_callback: Option<Box<dyn FnOnce()>>,
}

impl WatchHandle {
    pub(crate) fn new(stop_callback: Box<dyn FnOnce()>) -> Self {
        WatchHandle {
            stop_callback: Some(stop_callback),
        }
    }

    pub fn stop(self) {}
}

impl Drop for WatchHandle {
    fn drop(&mut self) {
        let callback = self.stop_callback.take().unwrap();
        callback();
    }
}

pub trait QueryMatches {
    type Object<'a>;

    fn matches<'a>(&self, id: i64, object: &Self::Object<'a>) -> bool;
}

pub(crate) struct ChangeSet {
    changes: IntMap<Arc<Watcher>>,
}

impl ChangeSet {
    pub fn new() -> Self {
        ChangeSet {
            changes: IntMap::new(),
        }
    }

    fn mark_watchers_changed(&mut self, watchers: &[Arc<Watcher>]) {
        for w in watchers {
            let registered = self.changes.contains_key(w.get_id());
            if !registered {
                self.changes.insert(w.get_id(), w.clone());
            } else {
                break;
            }
        }
    }

    pub fn register_change<Q: QueryMatches>(
        &mut self,
        cw: &CollectionWatchers<Q>,
        id: i64,
        object: &Q::Object<'_>,
    ) {
        let lock = cw.lock.read();
        self.mark_watchers_changed(&lock.watchers);
        if let Some(object_watchers) = lock.object_watchers.get(id as u64) {
            self.mark_watchers_changed(object_watchers);
        }

        for (q, w) in &lock.query_watchers {
            if !self.changes.contains_key(w.get_id()) && q.matches(id, object) {
                self.changes.insert(w.get_id(), w.clone());
            }
        }
    }

    pub fn register_all<Q: QueryMatches>(&mut self, cw: &CollectionWatchers<Q>) {
        let lock = cw.lock.read();
        self.mark_watchers_changed(&lock.watchers);
        for watchers in lock.object_watchers.values() {
            self.mark_watchers_changed(watchers)
        }
        for (_, w) in &lock.query_watchers {
            self.changes.insert(w.get_id(), w.clone());
        }
    }

    pub fn notify_watchers(&self) {
        for watcher in self.changes.values() {
            watcher.notify();
        }
    }
}

struct RawCollectionWatchers<Q: QueryMatches> {
    watchers: Vec<Arc<Watcher>>,
    object_watchers: IntMap<Vec<Arc<Watcher>>>,
    query_watchers: Vec<(Q, Arc<Watcher>)>,
}

pub struct CollectionWatchers<Q: QueryMatches> {
    lock: RwLock<RawCollectionWatchers<Q>>,
}

impl<Q: QueryMatches + 'static> CollectionWatchers<Q> {
    pub fn new() -> Arc<Self> {
        let raw = RawCollectionWatchers {
            watchers: Vec::new(),
            object_watchers: IntMap::new(),
            query_watchers: Vec::new(),
        };
        let watchers = CollectionWatchers {
            lock: RwLock::new(raw),
        };
        Arc::new(watchers)
    }

    pub fn watch(self: &Arc<Self>, callback: WatcherCallback) -> WatchHandle {
        let watcher = Arc::new(Watcher::new(callback));
        let watcher_id = watcher.get_id();
        self.lock.write().watchers.push(watcher);

        let watchers = self.clone();
        WatchHandle::new(Box::new(move || {
            watchers
                .lock
                .write()
                .watchers
                .retain(|w| w.get_id() != watcher_id);
        }))
    }

    pub fn watch_object(self: &Arc<Self>, id: i64, callback: WatcherCallback) -> WatchHandle {
        let watcher = Arc::new(Watcher::new(callback));
        let watcher_id = watcher.get_id();

        let mut lock = self.lock.write();
        if let Some(object_watchers) = lock.object_watchers.get_mut(id as u64) {
            object_watchers.push(watcher);
        } else {
            lock.object_watchers.insert(id as u64, vec![watcher]);
        }

        let watchers = self.clone();
        WatchHandle::new(Box::new(move || {
            let mut lock = watchers.lock.write();
            if let Some(object_watchers) = lock.object_watchers.get_mut(id as u64) {
                object_watchers.retain(|w| w.get_id() != watcher_id);
            }
        }))
    }

    pub fn watch_query(self: &Arc<Self>, query: Q, callback: WatcherCallback) -> WatchHandle {
        let watcher = Arc::new(Watcher::new(callback));
        let watcher_id = watcher.get_id();
        self.lock.write().query_watchers.push((query, watcher));

        let watchers = self.clone();
        WatchHandle::new(Box::new(move || {
            watchers
                .lock
                .write()
                .query_watchers
                .retain(|(_, w)| w.get_id() != watcher_id);
        }))
    }

    pub fn has_watchers(&self) -> bool {
        let lock = self.lock.read();
        !lock.watchers.is_empty()
            || !lock.object_watchers.is_empty()
            || !lock.query_watchers.is_empty()
    }
}
