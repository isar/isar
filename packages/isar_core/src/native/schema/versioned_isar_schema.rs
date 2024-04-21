use serde::{Deserialize, Serialize};

use crate::core::{
    error::{IsarError, Result},
    schema::IsarSchema,
};

use super::v2::v2_isar_schema::V2IsarSchema;

#[derive(Serialize, Deserialize)]
struct IsarSchemaVersion {
    #[serde(default)]
    version: u8,
}

pub enum VersionedIsarSchema {
    V2(V2IsarSchema),
    V3(IsarSchema),
}

impl VersionedIsarSchema {
    pub fn try_from_bytes(schema_name: &str, bytes: &[u8]) -> Result<Self> {
        let schema_version: IsarSchemaVersion =
            serde_json::from_slice(bytes).map_err(|_| IsarError::UnsupportedSchemaVersion {
                name: schema_name.to_owned(),
                version: None,
                message: "Could not find version of existing schema".to_owned(),
            })?;

        match schema_version.version {
            2 => {
                let schema: V2IsarSchema =
                    serde_json::from_slice(bytes).map_err(|_| IsarError::SchemaError {
                        message: "Could not deserialize existing v2 schema.".to_owned(),
                    })?;
                Ok(Self::V2(schema))
            }
            3 => {
                let schema: IsarSchema =
                    serde_json::from_slice(bytes).map_err(|_| IsarError::SchemaError {
                        message: "Could not deserialize existing v3 schema.".to_owned(),
                    })?;
                Ok(Self::V3(schema))
            }
            unsupported_version => Err(IsarError::UnsupportedSchemaVersion {
                name: schema_name.to_owned(),
                version: Some(unsupported_version),
                message: "Unsupported version".to_owned(),
            }),
        }
    }
}
