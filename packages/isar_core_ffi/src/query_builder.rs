use crate::{CIsarQuery, CIsarQueryBuilder};
use isar_core::core::query_builder::{IsarQueryBuilder, Sort};
use isar_core::filter::Filter;

#[no_mangle]
pub unsafe extern "C" fn isar_query_builder_set_filter(
    builder: &'static mut CIsarQueryBuilder,
    filter: *mut Filter,
) {
    let filter = *Box::from_raw(filter);
    match builder {
        CIsarQueryBuilder::Native(builder) => builder.set_filter(filter),
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_query_builder_set_offset(
    builder: &'static mut CIsarQueryBuilder,
    offset: u32,
) {
    match builder {
        CIsarQueryBuilder::Native(builder) => builder.set_offset(offset),
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_query_builder_set_limit(
    builder: &'static mut CIsarQueryBuilder,
    limit: u32,
) {
    match builder {
        CIsarQueryBuilder::Native(builder) => builder.set_limit(limit),
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_query_builder_add_sort(
    builder: &'static mut CIsarQueryBuilder,
    property_index: u16,
    ascending: bool,
) {
    let sort = if ascending { Sort::Asc } else { Sort::Desc };
    match builder {
        CIsarQueryBuilder::Native(builder) => builder.add_sort(property_index, sort),
    }
}

#[no_mangle]
pub unsafe extern "C" fn isar_query_builder_build(
    builder: *mut CIsarQueryBuilder,
) -> *mut CIsarQuery {
    let builder = *Box::from_raw(builder);
    match builder {
        CIsarQueryBuilder::Native(builder) => {
            let query = builder.build();
            Box::into_raw(Box::new(CIsarQuery::Native(query)))
        }
    }
}
