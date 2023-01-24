use super::mdbx::cursor::UnboundCursor;
use super::mdbx::env::Env;
use super::mdbx::txn::Txn;
use crate::core::error::{IsarError, Result};
use ouroboros::self_referencing;
use std::cell::RefCell;

#[self_referencing]
struct TxnEnv {
    env: Env,
    #[borrows(env)]
    #[covariant]
    txn: Option<Txn<'this>>,
}

pub struct NativeTxn {
    instance_id: u64,
    txn_env: TxnEnv,
    write: bool,
    unbound_cursors: RefCell<Option<Vec<UnboundCursor>>>,
}

impl NativeTxn {
    fn new(instance_id: u64, env: Env, write: bool) -> Result<Self> {
        let txn_env = TxnEnv::try_new(env, |env| {
            let txn = env.txn(write)?;
            Ok(Some(txn))
        })?;
        let unbound_cursors = RefCell::new(Some(Vec::new()));
        Ok(Self {
            instance_id,
            txn_env,
            write,
            unbound_cursors,
        })
    }

    pub(crate) fn verify_instance_id(&self, instance_id: u64) -> Result<()> {
        if self.instance_id != instance_id {
            Err(IsarError::InstanceMismatch {})
        } else {
            Ok(())
        }
    }

    pub(crate) fn commit(&mut self, instance_id: u64) -> Result<()> {
        let txn = self.txn_env.with_txn_mut(|txn| txn.take());
        if let Some(txn) = txn {
            txn.commit()?;
            Ok(())
        } else {
            Err(IsarError::TransactionClosed {})
        }
    }

    pub(crate) fn abort(&mut self, instance_id: u64) {
        let txn = self.txn_env.with_txn_mut(|txn| txn.take());
        if let Some(txn) = txn {
            txn.abort();
        }
    }

    pub(crate) fn finalize(self) -> Env {
        self.txn_env.into_heads().env
    }
}
