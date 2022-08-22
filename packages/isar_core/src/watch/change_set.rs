use crate::object::isar_object::IsarObject;
use crate::watch::isar_watchers::IsarWatchers;
use crate::watch::watcher::Watcher;
use intmap::IntMap;
use std::sync::{Arc, MutexGuard};

pub(crate) struct ChangeSet<'a> {
    watchers: MutexGuard<'a, IsarWatchers>,
    changed_watchers: IntMap<Arc<Watcher>>,
}

impl<'a> ChangeSet<'a> {
    pub fn new(watchers: MutexGuard<'a, IsarWatchers>) -> Self {
        ChangeSet {
            watchers,
            changed_watchers: IntMap::new(),
        }
    }

    fn register_watchers(changed_watchers: &mut IntMap<Arc<Watcher>>, watchers: &[Arc<Watcher>]) {
        for w in watchers {
            let registered = changed_watchers.contains_key(w.get_id());
            if !registered {
                changed_watchers.insert(w.get_id(), w.clone());
            } else {
                break;
            }
        }
    }

    pub fn register_change(&mut self, col_id: u64, id: i64, object: IsarObject) {
        let cw = self.watchers.get_col_watchers(col_id);
        Self::register_watchers(&mut self.changed_watchers, &cw.watchers);
        if let Some(object_watchers) = cw.object_watchers.get(id as u64) {
            Self::register_watchers(&mut self.changed_watchers, object_watchers);
        }

        for (q, w) in &cw.query_watchers {
            if !self.changed_watchers.contains_key(w.get_id())
                && q.maybe_matches_wc_filter(id, object)
            {
                self.changed_watchers.insert(w.get_id(), w.clone());
            }
        }
    }

    pub fn register_all(&mut self, col_id: u64) {
        let cw = self.watchers.get_col_watchers(col_id);
        Self::register_watchers(&mut self.changed_watchers, &cw.watchers);
        for watchers in cw.object_watchers.values() {
            Self::register_watchers(&mut self.changed_watchers, watchers)
        }
        for (_, w) in &cw.query_watchers {
            self.changed_watchers.insert(w.get_id(), w.clone());
        }
    }

    pub fn notify_watchers(self) {
        for watcher in self.changed_watchers.values() {
            watcher.notify();
        }
    }
}
