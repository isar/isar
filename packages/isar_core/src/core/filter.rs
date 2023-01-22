pub enum IsarValue {
    Bool(bool),
    Integer(i64),
    Real(f64),
    String(String),
}

pub trait IsarFilterBuilder {
    type Filter;

    fn null(&self, property_index: usize) -> Self::Filter;

    fn not_null(&self, property_index: usize) -> Self::Filter;

    fn gt(&self, property_index: usize, value: IsarValue) -> Self::Filter;

    fn gte(&self, property_index: usize, value: IsarValue) -> Self::Filter;

    fn lt(&self, property_index: usize, value: IsarValue) -> Self::Filter;

    fn lte(&self, property_index: usize, value: IsarValue) -> Self::Filter;

    fn eq(&self, property_index: usize, value: IsarValue) -> Self::Filter;

    fn neq(&self, property_index: usize, value: IsarValue) -> Self::Filter;

    fn between(&self, property_index: usize, lower: IsarValue, upper: IsarValue) -> Self::Filter;

    fn in_list(&self, property_index: usize, values: Vec<IsarValue>) -> Self::Filter;

    fn starts_with(&self, property_index: usize, value: &str) -> Self::Filter;

    fn ends_with(&self, property_index: usize, value: &str) -> Self::Filter;

    fn contains(&self, property_index: usize, value: &str) -> Self::Filter;

    fn and(filters: Vec<Self::Filter>) -> Self::Filter;

    fn or(filters: Vec<Self::Filter>) -> Self::Filter;

    fn not(filter: Self::Filter) -> Self::Filter;
}
