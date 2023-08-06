use snafu::Snafu;

pub type Result<T> = std::result::Result<T, IsarError>;

#[derive(Clone, Debug, Snafu, Eq, PartialEq)]
#[repr(u8)]
pub enum IsarError {
    #[snafu(display(
        "No such file or directory. Please make sure that the provided path is valid."
    ))]
    PathError {},

    #[snafu(display("Write transaction required."))]
    WriteTxnRequired {},

    #[snafu(display("Schema error: {}", message))]
    SchemaError {
        message: String,
    },

    #[snafu(display("Isar version of the file is too new or too old to be used."))]
    VersionError {},

    #[snafu(display(
        "Operation not supported. You might need to use a different flavor of Isar."
    ))]
    UnsupportedOperation {},

    #[snafu(display("Object limit reached."))]
    ObjectLimitReached {},

    #[snafu(display("Object insert incomplete."))]
    InsertIncomplete {},

    #[snafu(display("Instance mismatch. Make sure to use resources with the correct instance."))]
    InstanceMismatch {},

    #[snafu(display("Transaction closed."))]
    TransactionClosed {},

    #[snafu(display("Id not found."))]
    IdNotFound {},

    #[snafu(display("Unknown propery."))]
    UnknownProperty {},

    #[snafu(display("Transaction already active."))]
    TransactionActive {},

    #[snafu(display("Illegal String."))]
    IllegalString {},

    #[snafu(display("Illegal Argument."))]
    IllegalArgument {},

    #[snafu(display("Json Error: {}", message))]
    JsonError {
        message: String,
    },

    #[snafu(display("Encryption Error. Please make sure to use the correct encryption key."))]
    EncryptionError {},

    #[snafu(display("The database is full."))]
    DbFull {},

    DbCorrupted {},

    #[snafu(display("DbError ({}): {}", code, message))]
    DbError {
        code: i32,
        message: String,
    },
}
