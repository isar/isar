use crate::core::value::IsarValue;

#[derive(PartialEq, Clone, Debug)]
pub enum Filter {
    Condition(FilterCondition),
    Json(JsonCondition),
    Nested(FilterNested),
    And(Vec<Filter>),
    Or(Vec<Filter>),
    Not(Box<Filter>),
}

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum ConditionType {
    IsNull,
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

#[derive(Clone, PartialEq, Debug)]
pub struct JsonCondition {
    pub path: Vec<String>,
    pub condition_type: ConditionType,
    pub is_list: bool,
    pub values: Vec<Option<IsarValue>>,
    // if false, values are all lowercase
    pub case_sensitive: bool,
}

impl JsonCondition {
    pub fn new(
        path: Vec<String>,
        condition_type: ConditionType,
        is_list: bool,
        values: Vec<Option<IsarValue>>,
        case_sensitive: bool,
    ) -> Self {
        let values = if case_sensitive {
            values
        } else {
            values
                .into_iter()
                .map(|v| {
                    v.map(|v| {
                        if let IsarValue::String(s) = v {
                            IsarValue::String(s.to_lowercase())
                        } else {
                            v
                        }
                    })
                })
                .collect()
        };
        Self {
            path,
            condition_type,
            is_list,
            values,
            case_sensitive,
        }
    }
}

#[derive(PartialEq, Clone, Debug)]
pub struct FilterNested {
    pub property_index: u16,
    pub filter: Box<Filter>,
}

impl FilterNested {
    pub fn new(property_index: u16, filter: Filter) -> Self {
        FilterNested {
            property_index,
            filter: Box::new(filter),
        }
    }
}
