use crate::core::value::IsarValue;

#[derive(PartialEq, Clone, Debug)]
pub enum Filter {
    Condition(FilterCondition),
    Json(FilterJson),
    Embedded(FilterEmbedded),
    And(Vec<Filter>),
    Or(Vec<Filter>),
    Not(Box<Filter>),
}

impl Filter {
    pub fn new_condition(
        property_index: u16,
        condition_type: ConditionType,
        values: Vec<Option<IsarValue>>,
        case_sensitive: bool,
    ) -> Self {
        Filter::Condition(FilterCondition::new(
            property_index,
            condition_type,
            values,
            case_sensitive,
        ))
    }

    pub fn new_json(
        property_index: u16,
        path: Vec<String>,
        condition_type: ConditionType,
        values: Vec<Option<IsarValue>>,
        case_sensitive: bool,
    ) -> Self {
        Filter::Json(FilterJson::new(
            path,
            FilterCondition::new(property_index, condition_type, values, case_sensitive),
        ))
    }

    pub fn new_embedded(property_index: u16, filter: Filter) -> Self {
        Filter::Embedded(FilterEmbedded::new(property_index, filter))
    }

    pub fn new_and(filters: Vec<Filter>) -> Self {
        Filter::And(filters)
    }

    pub fn new_or(filters: Vec<Filter>) -> Self {
        Filter::Or(filters)
    }

    pub fn new_not(filter: Filter) -> Self {
        Filter::Not(Box::new(filter))
    }
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
    StringRegex,
    In,
}

#[derive(Clone, PartialEq, Debug)]
pub struct FilterCondition {
    pub property_index: u16,
    pub condition_type: ConditionType,
    pub values: Vec<Option<IsarValue>>,
    // if false, values are all lowercase
    pub case_sensitive: bool,
}

impl FilterCondition {
    fn new(
        property_index: u16,
        condition_type: ConditionType,
        mut values: Vec<Option<IsarValue>>,
        case_sensitive: bool,
    ) -> Self {
        if !case_sensitive {
            for i in 0..values.len() {
                if let Some(IsarValue::String(s)) = &values[i] {
                    values[i] = Some(IsarValue::String(s.to_lowercase()));
                }
            }
        }
        Self {
            property_index,
            condition_type,
            values,
            case_sensitive,
        }
    }
}

#[derive(Clone, PartialEq, Debug)]
pub struct FilterJson {
    pub path: Vec<String>,
    pub condition: FilterCondition,
}

impl FilterJson {
    fn new(path: Vec<String>, condition: FilterCondition) -> Self {
        Self { path, condition }
    }
}

#[derive(PartialEq, Clone, Debug)]
pub struct FilterEmbedded {
    pub property_index: u16,
    pub filter: Box<Filter>,
}

impl FilterEmbedded {
    fn new(property_index: u16, filter: Filter) -> Self {
        FilterEmbedded {
            property_index,
            filter: Box::new(filter),
        }
    }
}
