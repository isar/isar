use snafu::Snafu;

pub type Result<T> = std::result::Result<T, IsarError>;

#[derive(Clone, Debug, Snafu, Eq, PartialEq)]
pub enum IsarError {
    #[snafu(display("Isar version of the file is too new or too old to be used."))]
    VersionError {},

    #[snafu(display(
        "No such file or directory. Please make sure that the provided path is valid."
    ))]
    PathError {},

    #[snafu(display("Cannot open database connection: {}", error))]
    ConnError { error: Box<IsarError> },

    #[snafu(display("The database is full."))]
    DbFull {},

    #[snafu(display("Unique index violated."))]
    UniqueViolated {},

    #[snafu(display("Write transaction required."))]
    WriteTxnRequired {},

    #[snafu(display("Auto increment id cannot be generated because the limit is reached."))]
    AutoIncrementOverflow {},

    #[snafu(display("Transaction closed."))]
    TransactionClosed {},

    #[snafu(display("IllegalArg: {}.", message))]
    IllegalArg { message: String },

    #[snafu(display("Index could not be found."))]
    UnknownIndex {},

    #[snafu(display("Invalid JSON."))]
    InvalidJson {},

    #[snafu(display("DbCorrupted: {}", message))]
    DbCorrupted { message: String },

    #[snafu(display("SchemaError: {}", message))]
    SchemaError { message: String },

    #[snafu(display("SchemaMismatch: The schema of the existing instance does not match."))]
    SchemaMismatch {},

    #[snafu(display("InstanceMismatch: The transaction is from a different instance."))]
    InstanceMismatch {},

    #[snafu(display("DbError ({}): {}", code, message))]
    DbError { code: i32, message: String },
}

pub fn illegal_arg<T>(msg: &str) -> Result<T> {
    Err(IsarError::IllegalArg {
        message: msg.to_string(),
    })
}

pub fn schema_error<T>(msg: &str) -> Result<T> {
    Err(IsarError::SchemaError {
        message: msg.to_string(),
    })
}
