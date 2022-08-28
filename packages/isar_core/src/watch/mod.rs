pub(crate) mod change_set;
pub(crate) mod isar_watchers;
pub(crate) mod watcher;

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
