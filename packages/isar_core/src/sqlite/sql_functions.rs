use super::{sqlite_query::JsonCondition, sqlite3::SQLiteFnContext};
use crate::core::error::Result;
use crate::core::filter_json::matches_json;
use regex::{Regex, RegexBuilder};
use serde_json::Value;
use std::borrow::Cow;

pub(crate) const FN_FILTER_JSON_NAME: &str = "isar_filter_json";
pub(crate) const FN_FILTER_JSON_COND_PTR_TYPE: &[u8] = b"json_condition_ptr\0";
pub(crate) fn sql_fn_filter_json(ctx: &mut SQLiteFnContext) -> Result<()> {
    let json = if let Some(json) = ctx.get_auxdata::<Value>(0) {
        Cow::Borrowed(json)
    } else {
        let json_str = ctx.get_str(0);
        let json = serde_json::from_str::<Value>(json_str).unwrap_or(Value::Null);
        Cow::Owned(Box::new(json))
    };

    let condition = ctx.get_object::<JsonCondition>(1, FN_FILTER_JSON_COND_PTR_TYPE);

    if let Some(condition) = condition {
        let result = matches_json(
            &json,
            condition.condition_type,
            &condition.path,
            &condition.values,
            None,
            condition.case_sensitive,
        );
        ctx.set_int_result(if result { 1 } else { 0 });
    }

    if let Cow::Owned(mut json) = json {
        ctx.set_auxdata(0, json.take());
    }

    Ok(())
}

pub(crate) const FN_MATCHES_REGEX_NAME: &str = "isar_matches_regex";
pub(crate) fn sql_fn_matches_regex(ctx: &mut SQLiteFnContext) -> Result<()> {
    let regex = if let Some(regex) = ctx.get_auxdata::<Option<Regex>>(0) {
        Cow::Borrowed(regex)
    } else {
        let regex_str = ctx.get_str(0);
        let case_sensitive = ctx.get_int(1) != 0;
        let mut builder = RegexBuilder::new(regex_str);
        builder.case_insensitive(!case_sensitive);
        Cow::Owned(Box::new(builder.build().ok()))
    };

    if let Some(regex) = regex.as_ref().as_ref() {
        let result = regex.is_match(ctx.get_str(2));
        ctx.set_int_result(if result { 1 } else { 0 });
    }

    if let Cow::Owned(mut regex) = regex {
        ctx.set_auxdata(0, regex.take());
    }

    Ok(())
}
