use crate::core::value::IsarValue;

#[derive(PartialEq, Clone, Debug)]
pub enum Filter {
    Condition(FilterCondition),
    Nested(FilterNested),
    And(Vec<Filter>),
    Or(Vec<Filter>),
    Not(Box<Filter>),
}

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum ConditionType {
    IsNull,
    ListIsEmpty,
    Equal,
    Greater,
    GreaterOrEqual,
    Less,
    LessOrEqual,
    Between,
    StringStartsWith,
    StringEndsWith,
    StringContains,
    StringMatches,
}

#[derive(Clone, PartialEq, Debug)]
pub struct FilterCondition {
    pub property_index: u16,
    pub condition_type: ConditionType,
    pub values: Vec<Option<IsarValue>>,
    pub case_sensitive: bool,
}

impl FilterCondition {
    pub const fn new(
        property_index: u16,
        condition_type: ConditionType,
        values: Vec<Option<IsarValue>>,
        case_sensitive: bool,
    ) -> Self {
        Self {
            property_index,
            condition_type,
            values,
            case_sensitive,
        }
    }
}

#[derive(PartialEq, Clone, Debug)]
pub struct FilterNested {
    collection_index: u16,
    filter: Box<Filter>,
}

impl FilterNested {
    pub fn new(collection_index: u16, filter: Filter) -> Self {
        FilterNested {
            collection_index,
            filter: Box::new(filter),
        }
    }
}
