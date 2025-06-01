use crate::core::query_builder::Sort;
use crate::native::native_collection::NativeProperty;
use crate::native::native_index::NativeIndex;

pub struct SortIndexMatch<'a> {
    // primary index or secondary index that are recommended
    index: Option<&'a NativeIndex>,
    index_direction: Sort,
    remaining_sort: Vec<(Option<NativeProperty>, Sort, bool)>,
}

// Finds the best index to optimize or eliminate sorting operations
//
// Rules for index matching:
// 1. Properties must appear in the same order in both the index and sort specification
// 2. Only considers consecutive properties from the start that have:
//    - The same sort direction (all Asc or all Desc)
//    - Case sensitive sorting (case insensitive sorting is not supported)
//    - Non-null properties (ID property cannot be part of an index)
// 3. Hashed indexes are not considered for sorting
//
// The function returns:
// - The best matching index (if any)
// - The direction to traverse the index
// - Any remaining sort properties that couldn't be satisfied by the index
//
// Example:
// For sort [(prop1, Asc), (prop2, Asc), (prop3, Desc)]
// And index [prop1, prop2, prop4]
// It will match prop1 and prop2 using the index, with prop3 remaining for in-memory sort
pub fn index_matching_sort<'a>(
    indexes: &'a [NativeIndex],
    sort: &[(Option<NativeProperty>, Sort, bool)],
) -> Option<SortIndexMatch<'a>> {
    if sort.is_empty() {
        return None;
    }

    // Check if we are sorting only by id
    if sort.len() == 1 && sort[0].0.is_none() {
        return Some(SortIndexMatch {
            index: None,
            index_direction: sort[0].1,
            remaining_sort: vec![],
        });
    }

    // Find the number of properties that have the same sort direction and are case sensitive
    let mut max_properties = 0;
    let mut sort_direction = None;
    for (property, sort, case_sensitive) in sort {
        if !case_sensitive {
            break;
        }
        if property.is_none() {
            // Id property cannot be part of an index
            break;
        }
        if let Some(sort_direction) = sort_direction {
            if sort_direction != *sort {
                break;
            }
        } else {
            sort_direction = Some(*sort);
        }
        max_properties += 1;
    }

    if max_properties == 0 {
        // No properties support index based sorting
        return None;
    }

    let mut best_index = None;
    let mut best_index_properties = 0;
    for index in indexes {
        if index.hash {
            continue;
        }

        let mut matching_properties = 0;

        // Check each index property against sort properties
        for (i, index_prop) in index.properties.iter().take(max_properties).enumerate() {
            let sort_prop = &sort[i].0;
            if sort_prop.as_ref() == Some(index_prop) {
                matching_properties += 1;
            } else {
                break;
            }
        }

        // Update best match if this index has more matching properties
        if matching_properties > best_index_properties {
            best_index = Some(index);
            best_index_properties = matching_properties;
        }
    }

    if let Some(best_index) = best_index {
        Some(SortIndexMatch {
            index: Some(best_index),
            index_direction: sort_direction.unwrap(),
            remaining_sort: sort.iter().skip(best_index_properties).cloned().collect(),
        })
    } else {
        None
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{core::data_type::DataType, native::mdbx::db::Db};

    fn create_property(offset: u32) -> NativeProperty {
        NativeProperty::new(DataType::Int, offset, None)
    }

    fn create_index(name: &str, property_offsets: &[u32], hash: bool) -> NativeIndex {
        let properties = property_offsets
            .iter()
            .map(|&offset| create_property(offset))
            .collect();
        NativeIndex::new(name, Db::mock(), properties, false, hash)
    }

    macro_rules! assert_index_match {
        ($index_name:expr, $sort_dir:expr, $indexes:expr, $sort:expr, remaining: $remaining:expr) => {
            let result = index_matching_sort($indexes, $sort).unwrap();
            assert_eq!(result.index.unwrap().name, $index_name);
            assert_eq!(result.index_direction, $sort_dir);
            assert_eq!(result.remaining_sort.len(), $remaining);
            for i in 0..$remaining {
                assert_eq!(
                    result.remaining_sort[i],
                    $sort[$sort.len() - $remaining + i]
                );
            }
        };
    }

    #[test]
    fn test_empty_sort() {
        let indexes = vec![];
        let sort = vec![];
        assert!(index_matching_sort(&indexes, &sort).is_none());
    }

    #[test]
    fn test_sort_by_id_only_asc() {
        let indexes = vec![create_index("test", &[1, 2, 3], false)];
        let sort = vec![(None, Sort::Asc, true)];
        let result = index_matching_sort(&indexes, &sort).unwrap();
        assert!(result.index.is_none());
        assert_eq!(result.index_direction, Sort::Asc);
        assert!(result.remaining_sort.is_empty());
    }

    #[test]
    fn test_sort_by_id_only_desc() {
        let indexes = vec![];
        let sort = vec![(None, Sort::Desc, true)];
        let result = index_matching_sort(&indexes, &sort).unwrap();
        assert!(result.index.is_none());
        assert_eq!(result.index_direction, Sort::Desc);
        assert!(result.remaining_sort.is_empty());
    }

    #[test]
    fn test_sort_by_id_and_property() {
        let indexes = vec![create_index("test", &[1], false)];
        let sort = vec![
            (None, Sort::Asc, true),
            (Some(create_property(1)), Sort::Asc, true),
        ];
        assert!(index_matching_sort(&indexes, &sort).is_none());
    }

    #[test]
    fn test_case_insensitive_no_match() {
        let indexes = vec![create_index("test", &[1], false)];
        let sort = vec![(Some(create_property(1)), Sort::Asc, false)];
        assert!(index_matching_sort(&indexes, &sort).is_none());
    }

    #[test]
    fn test_case_sensitive_then_insensitive() {
        let indexes = vec![create_index("test", &[1, 2], false)];
        let sort = vec![
            (Some(create_property(1)), Sort::Asc, true),
            (Some(create_property(2)), Sort::Asc, false),
        ];
        assert_index_match!("test", Sort::Asc, &indexes, &sort, remaining: 1);
    }

    #[test]
    fn test_two_case_sensitive_then_insensitive() {
        let indexes = vec![create_index("test", &[1, 2, 3], false)];
        let sort = vec![
            (Some(create_property(1)), Sort::Asc, true),
            (Some(create_property(2)), Sort::Asc, true),
            (Some(create_property(3)), Sort::Asc, false),
        ];
        assert_index_match!("test", Sort::Asc, &indexes, &sort, remaining: 1);
    }

    #[test]
    fn test_mixed_sort_directions_different() {
        let indexes = vec![create_index("test", &[1, 2], false)];
        let sort = vec![
            (Some(create_property(1)), Sort::Asc, true),
            (Some(create_property(2)), Sort::Desc, true),
        ];
        assert_index_match!("test", Sort::Asc, &indexes, &sort, remaining: 1);
    }

    #[test]
    fn test_mixed_sort_directions_matching() {
        let indexes = vec![create_index("test", &[1, 2], false)];
        let sort = vec![
            (Some(create_property(1)), Sort::Desc, true),
            (Some(create_property(2)), Sort::Desc, true),
        ];
        assert_index_match!("test", Sort::Desc, &indexes, &sort, remaining: 0);
    }

    #[test]
    fn test_sort_with_id_in_middle() {
        let indexes = vec![create_index("test", &[1, 2, 3], false)];
        let sort = vec![
            (Some(create_property(1)), Sort::Asc, true),
            (None, Sort::Asc, true),
            (Some(create_property(3)), Sort::Asc, true),
        ];
        assert_index_match!("test", Sort::Asc, &indexes, &sort, remaining: 2);
    }

    #[test]
    fn test_hashed_index() {
        let indexes = vec![create_index("test", &[1], true)];
        let sort = vec![(Some(create_property(1)), Sort::Asc, true)];
        assert!(index_matching_sort(&indexes, &sort).is_none());
    }

    #[test]
    fn test_multiple_indexes() {
        let indexes = vec![
            create_index("test1", &[1], false),
            create_index("test2", &[1, 2], false),
        ];
        let sort = vec![
            (Some(create_property(1)), Sort::Asc, true),
            (Some(create_property(2)), Sort::Asc, true),
        ];
        assert_index_match!("test2", Sort::Asc, &indexes, &sort, remaining: 0);
    }

    #[test]
    fn test_no_matching_indexes() {
        let indexes = vec![create_index("test", &[2], false)];
        let sort = vec![(Some(create_property(1)), Sort::Asc, true)];
        assert!(index_matching_sort(&indexes, &sort).is_none());
    }

    #[test]
    fn test_perfect_index_match() {
        let indexes = vec![create_index("test", &[1, 2], false)];
        let sort = vec![
            (Some(create_property(1)), Sort::Asc, true),
            (Some(create_property(2)), Sort::Asc, true),
        ];
        assert_index_match!("test", Sort::Asc, &indexes, &sort, remaining: 0);
    }

    #[test]
    fn test_index_longer_than_sort() {
        let indexes = vec![create_index("test", &[1, 2, 3], false)];
        let sort = vec![
            (Some(create_property(1)), Sort::Asc, true),
            (Some(create_property(2)), Sort::Asc, true),
        ];
        assert_index_match!("test", Sort::Asc, &indexes, &sort, remaining: 0);
    }

    #[test]
    fn test_sort_longer_than_index() {
        let indexes = vec![create_index("test", &[1], false)];
        let sort = vec![
            (Some(create_property(1)), Sort::Asc, true),
            (Some(create_property(2)), Sort::Asc, true),
        ];
        assert_index_match!("test", Sort::Asc, &indexes, &sort, remaining: 1);
    }
}
