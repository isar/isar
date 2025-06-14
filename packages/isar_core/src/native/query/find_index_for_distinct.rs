use crate::native::native_collection::NativeProperty;
use crate::native::native_index::NativeIndex;

// Finds the best index to optimize or eliminate sorting operations.
// Only unique indexes and case sensitive distincts are considered.
pub fn index_matching_distinct<'a>(
    indexes: &'a [NativeIndex],
    distinct: &[(NativeProperty, bool)],
) -> Option<&'a NativeIndex> {
    let mut best_index = None;
    let mut best_index_remaining = distinct.len();
    for index in indexes {
        if !index.unique {
            continue;
        }
        let remaining = index_remaining_distinct_properties(index, distinct);
        if remaining.len() < best_index_remaining {
            best_index_remaining = remaining.len();
            best_index = Some(index);
        }
    }
    best_index
}

// Finds the remaining distinct properties that are not part of the index.
pub fn index_remaining_distinct_properties<'a>(
    index: &'a NativeIndex,
    distinct: &[(NativeProperty, bool)],
) -> Vec<NativeProperty> {
    if !index.unique {
        return distinct.iter().map(|(property, _)| *property).collect();
    }

    let mut remaining = vec![];
    for (property, case_sensitive) in distinct {
        if !case_sensitive || !index.properties.contains(property) {
            remaining.push(*property);
        }
    }
    remaining
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{core::data_type::DataType, native::mdbx::db::Db};

    fn test_index(properties: Vec<NativeProperty>, unique: bool) -> NativeIndex {
        NativeIndex::new("test_index", Db::mock(), properties, unique, false)
    }

    fn create_prop(offset: u32) -> NativeProperty {
        NativeProperty::new(DataType::Int, offset, None)
    }

    #[test]
    fn test_index_remaining_distinct_properties_empty() {
        let index = test_index(vec![], true);
        let distinct = vec![];
        assert_eq!(
            index_remaining_distinct_properties(&index, &distinct),
            vec![]
        );
    }

    #[test]
    fn test_index_remaining_distinct_properties_non_unique() {
        let index = test_index(vec![create_prop(0)], false);
        let distinct = vec![(create_prop(0), true)];
        assert_eq!(
            index_remaining_distinct_properties(&index, &distinct),
            vec![create_prop(0)]
        );
    }

    #[test]
    fn test_index_remaining_distinct_properties_case_insensitive() {
        let index = test_index(vec![create_prop(0)], true);
        let distinct = vec![(create_prop(0), false)];
        assert_eq!(
            index_remaining_distinct_properties(&index, &distinct),
            vec![create_prop(0)]
        );
    }

    #[test]
    fn test_index_remaining_distinct_properties_not_in_index() {
        let index = test_index(vec![create_prop(0)], true);
        let distinct = vec![(create_prop(1), true)];
        assert_eq!(
            index_remaining_distinct_properties(&index, &distinct),
            vec![create_prop(1)]
        );
    }

    #[test]
    fn test_index_remaining_distinct_properties_mixed() {
        let index = test_index(vec![create_prop(0), create_prop(1)], true);
        let distinct = vec![
            (create_prop(0), true),  // Should be matched
            (create_prop(1), false), // Case insensitive, should remain
            (create_prop(2), true),  // Not in index, should remain
        ];
        assert_eq!(
            index_remaining_distinct_properties(&index, &distinct),
            vec![create_prop(1), create_prop(2)]
        );
    }

    #[test]
    fn test_index_matching_distinct_empty() {
        let indexes: Vec<NativeIndex> = vec![];
        let distinct = vec![];
        assert_eq!(index_matching_distinct(&indexes, &distinct), None);
    }

    #[test]
    fn test_index_matching_distinct_no_unique_indexes() {
        let indexes = vec![
            test_index(vec![create_prop(0)], false),
            test_index(vec![create_prop(1)], false),
        ];
        let distinct = vec![(create_prop(0), true)];
        assert_eq!(index_matching_distinct(&indexes, &distinct), None);
    }

    #[test]
    fn test_index_matching_distinct_single_match() {
        let index = test_index(vec![create_prop(0)], true);
        let indexes = vec![index];
        let distinct = vec![(create_prop(0), true)];
        assert_eq!(
            index_matching_distinct(&indexes, &distinct),
            Some(&indexes[0])
        );
    }

    #[test]
    fn test_index_matching_distinct_best_match() {
        let index1 = test_index(vec![create_prop(0)], true);
        let index2 = test_index(vec![create_prop(0), create_prop(1)], true);
        let indexes = vec![index1, index2];
        let distinct = vec![(create_prop(0), true), (create_prop(1), true)];
        // Should choose index2 as it covers more properties
        assert_eq!(
            index_matching_distinct(&indexes, &distinct),
            Some(&indexes[1])
        );
    }

    #[test]
    fn test_index_matching_distinct_case_sensitive_preference() {
        let index1 = test_index(vec![create_prop(0)], true);
        let index2 = test_index(vec![create_prop(1)], true);
        let indexes = vec![index1, index2];
        let distinct = vec![
            (create_prop(0), false), // Case insensitive
            (create_prop(1), true),  // Case sensitive
        ];
        // Should choose index2 as it matches the case-sensitive distinct
        assert_eq!(
            index_matching_distinct(&indexes, &distinct),
            Some(&indexes[1])
        );
    }

    #[test]
    fn test_index_matching_distinct_multiple_candidates() {
        let index1 = test_index(vec![create_prop(0), create_prop(1)], true);
        let index2 = test_index(vec![create_prop(0), create_prop(2)], true);
        let indexes = vec![index1, index2];
        let distinct = vec![
            (create_prop(0), true),
            (create_prop(1), true),
            (create_prop(2), true),
        ];
        // Should choose first matching index as they both have same number of remaining properties
        assert_eq!(
            index_matching_distinct(&indexes, &distinct),
            Some(&indexes[0])
        );
    }
}
