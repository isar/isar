pub type WatcherCallback = Box<dyn Fn() + Send + Sync + 'static>;

pub(super) struct Watcher {
    id: u64,
    callback: WatcherCallback,
}

impl Watcher {
    pub fn new(id: u64, callback: WatcherCallback) -> Self {
        Watcher { id, callback }
    }

    pub fn get_id(&self) -> u64 {
        self.id
    }

    pub fn notify(&self) {
        (*self.callback)()
    }
}
