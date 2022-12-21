use crate::core::schema::CollectionSchema;

use super::SqlExt;

pub fn sql_create_table(collection: &CollectionSchema) -> String {
    let mut sql = String::new();
    sql.push_str("CREATE TABLE ");
    sql.push_str(&collection.name);
    sql.push_str(" (");
    sql.push_str("id INTEGER PRIMARY KEY");
    for (i, property) in collection.properties.iter().enumerate() {
        if property.name.is_some() {
            sql.push_str(", c");
            sql.push_str(&i.to_string());
            sql.push_str(" ");
            sql.push_str(&property.data_type.to_sql());
        }
    }
    sql.push_str(");");
    sql
}
