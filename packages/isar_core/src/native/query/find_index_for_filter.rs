use crate::core::filter::Filter;
use crate::native::native_index::NativeIndex;

pub fn index_matching_filter<'a>(
    indexes: &'a [NativeIndex],
    filter: &Filter,
) -> Vec<(&'a NativeIndex, Filter)> {
    match filter {
        Filter::Condition(_) => {
            let vec = vec![filter.clone()];
            index_matching_and_filter(indexes, &vec)
        }
        Filter::And(filters) => index_matching_and_filter(indexes, filters),
        Filter::Or(filters) => index_matching_or_filter(indexes, filters),
        _ => vec![],
    }
}

fn index_matching_and_filter<'a>(
    indexes: &'a [NativeIndex],
    filters: &[Filter],
) -> Vec<(&'a NativeIndex, Filter)> {
    let matches = vec![];
    for index in indexes {
        /*if index_matching_and_filter(index, filters) {
            matches.push((index, filter));
        }*/
    }
    matches
}

fn index_matching_or_filter<'a>(
    indexes: &'a [NativeIndex],
    filters: &[Filter],
) -> Vec<(&'a NativeIndex, Filter)> {
    todo!()
}
