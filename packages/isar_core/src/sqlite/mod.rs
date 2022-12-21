use crate::core::error::IsarError;

pub mod sqlite_collection;
pub mod sqlite_instance;
pub mod sqlite_object;
pub mod sqlite_query;
pub mod sqlite_txn;

mod sql;

impl From<rusqlite::Error> for IsarError {
    fn from(err: rusqlite::Error) -> Self {
        match err {
            rusqlite::Error::SqliteFailure(error, _) => {
                if error.code == rusqlite::ErrorCode::ConstraintViolation {
                    IsarError::UniqueViolated {}
                } else {
                    IsarError::DbError {
                        code: error.code as i32,
                        message: error.to_string(),
                    }
                }
            }
            rusqlite::Error::InvalidPath(_) => IsarError::PathError {},
            err => IsarError::DbError {
                code: 1,
                message: err.to_string(),
            },
        }
    }
}
