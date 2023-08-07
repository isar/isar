use arc_swap::ArcSwap;
use intmap::IntMap;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::Arc;

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

pub(crate) trait QueryMatches: Clone {
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
        let w = cw.col_watchers.load();
        self.mark_watchers_changed(&w.watchers);
        if let Some(object_watchers) = w.object_watchers.get(id as u64) {
            self.mark_watchers_changed(object_watchers);
        }

        for (q, watcher) in &w.query_watchers {
            if !self.changes.contains_key(watcher.get_id()) && q.matches(id, object) {
                self.changes.insert(watcher.get_id(), watcher.clone());
            }
        }
    }

    pub fn register_all<Q: QueryMatches>(&mut self, cw: &CollectionWatchers<Q>) {
        let w = cw.col_watchers.load();
        self.mark_watchers_changed(&w.watchers);
        for watchers in w.object_watchers.values() {
            self.mark_watchers_changed(watchers)
        }
        for (_, watcher) in &w.query_watchers {
            self.changes.insert(watcher.get_id(), watcher.clone());
        }
    }

    pub fn notify_watchers(&self) {
        for watcher in self.changes.values() {
            watcher.notify();
        }
    }
}

#[derive(Clone)]
struct RawCollectionWatchers<Q: QueryMatches> {
    watchers: Vec<Arc<Watcher>>,
    object_watchers: IntMap<Vec<Arc<Watcher>>>,
    query_watchers: Vec<(Q, Arc<Watcher>)>,
}

pub(crate) struct CollectionWatchers<Q: QueryMatches> {
    col_watchers: ArcSwap<RawCollectionWatchers<Q>>,
}

impl<Q: QueryMatches + 'static> CollectionWatchers<Q> {
    pub fn new() -> Arc<Self> {
        let raw = RawCollectionWatchers {
            watchers: Vec::new(),
            object_watchers: IntMap::new(),
            query_watchers: Vec::new(),
        };
        let watchers = CollectionWatchers {
            col_watchers: ArcSwap::new(Arc::new(raw)),
        };
        Arc::new(watchers)
    }

    pub fn watch(self: &Arc<Self>, callback: WatcherCallback) -> WatchHandle {
        let watcher = Arc::new(Watcher::new(callback));
        let watcher_id = watcher.get_id();

        let watchers = self.clone();
        watchers.col_watchers.rcu(|cw| {
            let mut cw = (**cw).clone();
            cw.watchers.push(watcher.clone());
            cw
        });

        WatchHandle::new(Box::new(move || {
            watchers.col_watchers.rcu(|cw| {
                let mut cw = (**cw).clone();
                cw.watchers.retain(|w| w.get_id() != watcher_id);
                cw
            });
        }))
    }

    pub fn watch_object(self: &Arc<Self>, id: i64, callback: WatcherCallback) -> WatchHandle {
        let watcher = Arc::new(Watcher::new(callback));
        let watcher_id = watcher.get_id();

        let watchers = self.clone();
        watchers.col_watchers.rcu(|cw| {
            let mut cw = (**cw).clone();
            if let Some(object_watchers) = cw.object_watchers.get_mut(id as u64) {
                object_watchers.push(watcher.clone());
            } else {
                cw.object_watchers.insert(id as u64, vec![watcher.clone()]);
            }
            cw
        });

        WatchHandle::new(Box::new(move || {
            watchers.col_watchers.rcu(|cw| {
                let mut cw = (**cw).clone();
                if let Some(object_watchers) = cw.object_watchers.get_mut(id as u64) {
                    object_watchers.retain(|w| w.get_id() != watcher_id);
                }
                Arc::new(cw)
            });
        }))
    }

    pub fn watch_query(self: &Arc<Self>, query: &Q, callback: WatcherCallback) -> WatchHandle {
        let watcher = Arc::new(Watcher::new(callback));
        let watcher_id = watcher.get_id();

        let watchers = self.clone();
        watchers.col_watchers.rcu(|cw| {
            let mut cw = (**cw).clone();
            cw.query_watchers.push((query.clone(), watcher.clone()));
            Arc::new(cw)
        });

        WatchHandle::new(Box::new(move || {
            watchers.col_watchers.rcu(|cw| {
                let mut cw = (**cw).clone();
                cw.query_watchers.retain(|(_, w)| w.get_id() != watcher_id);
                Arc::new(cw)
            });
        }))
    }

    pub fn has_query_watchers(&self) -> bool {
        !self.col_watchers.load().query_watchers.is_empty()
    }

    pub fn has_watchers(&self) -> bool {
        let w = self.col_watchers.load();
        !w.watchers.is_empty() || !w.object_watchers.is_empty() || !w.query_watchers.is_empty()
    }
}
