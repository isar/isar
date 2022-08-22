use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Clone, Eq, PartialEq)]
pub struct LinkSchema {
    pub(crate) name: String,
    #[serde(rename = "target")]
    pub(crate) target_col: String,
}

impl LinkSchema {
    pub fn new(name: &str, target_collection_name: &str) -> Self {
        LinkSchema {
            name: name.to_string(),
            target_col: target_collection_name.to_string(),
        }
    }
}
