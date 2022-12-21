use crate::core::error::Result;

pub trait IsarTxn<'a> {
    fn is_active(&self) -> bool;

    fn commit(self) -> Result<()>;

    fn abort(self);
}
