use super::error::Result;

pub trait IsarTxn {
    fn commit(self) -> Result<()>;

    fn abort(self);
}
