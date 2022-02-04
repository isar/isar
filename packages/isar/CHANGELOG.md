## 2.2.0
- Improved write performance
- Added `deleteFromDisk` option to `isar.close()`

## 2.1.4

- Removed `path` dependency
- Fixed incorrect return value of `deleteByIndex()`
- Fixed wrong auto increment ids in some cases (thanks @robban112)
- Fixed an issue with `Isar.close()` (thanks @msxenon)
- Fixed `$` escaping in generated code (thanks @jtzell)
- Fixed broken link in pub.dev example page

## 2.1.0
`isar_connect` is now integrated into `isar`

### Enhancements
- Added check for outdated generated files
- Added check for changed schema across isolates
- Added `Isar.openSync()`
- Added `col.importJsonRawSync()`, `col.importJsonSync()`, `query.exportJsonRawSync()`, `query.exportJsonSync()`
- Improved performance for queries
- Improved handling of ffi memory
- More tests

### Fixed
- Fixed issue where imported json required existing ids
- Fixed issue with transaction handling (thanks @Peng-Qian for the awesome help)
- Fixed issue with `@Ignore` annotation not always working
- Fixed issue with `getByIndex()` not returning correct object id (thanks @jtzell)

## 2.0.0

### Breaking
- The id for non-final objects is now assigned automatically after `.put()` and `.putSync()`
- `double` and `List<double>` indexes can no longer be at the beginning of a composite index
- `List<double>` indexes can no longer be hashed
- `.greaterThan()`, `.lessThan()` and `.between()` filters and are now excluding for `double` values (`>=` -> `>`)
- Changed the default index type for lists to `IndexType.value`
- `IsarLink` and `IsarLinks` will no longer be initialized by Isar and must not be `nullable` or `late`.
- Dart `2.14` or higher is required

### Enhancements
- Added API docs for all public methods
- Added `isar.clear()`, `isar.clearSync()`, `col.clear()` and `col.clearSync()`
- Added `col.filter()` as shortcut for `col.where().filter()`
- Added `include` parameter to `.greaterThan()` and `.lessThan()` filters and where clauses
- Added `includeLower` and `includeUpper` parameters to `.between()` filters and where clauses
- Added `Isar.autoIncrement` to allow non-nullable auto-incrementing ids
- `Isar.close()` now returns whether the last instance was closed
- List values in composite indexes are now of type `IndexType.hash` automatically
- Allowed multiple indexes on the same property
- Removed exported packages from API docs
- Improved generated code
- Imoroved Isar Core error messages
- Minor performance improvements
- Automatic XCode configuration
- Updated analyzer to `3.0.0`
- More tests

### Fixed
- `IsarLink` and `IsarLinks` can now be final
- Fixed multi-entry index queries returning items multiple times in some cases
- Fixed `.anyLessThan()` and `.anyGreaterThan()` issues
- Fixed issues with backlinks
- Fixed issue where query only returned the first `99999` results
- Fixed issue with id where clauses
- Fixed default index type for lists and bytes
- Fixed issue where renaming indexes was not possible
- Fixed issue where wrong index name was used for `.getByX()` and `.deleteByX()`
- Fixed issue where composite indexes did not allow non-hashed Strings as last value
- Fixed issue where `@Ignore()` fields were not ignored

## 1.0.5

### Enhancements
- Updated dependencies

### Fixes:
- Included desktop binaries
- Fixed "Cannot allocate memory" error on older iOS devices
- Fixed stripped binaries for iOS release builds
- Fixed IsarInspector issues (thanks to [RubenBez](https://github.com/RubenBez) and [rizzi37](https://github.com/rizzi37))

## 1.0.0+1

Added missing binaries

## 1.0.0

Switched from liblmdb to libmdbx for better performance, more stability and many internal improvements.

### Breaking
The internal database format has been changed to improve performance. Old databases do not work anymore!

### Fixes
- Fix issue with links being removed after object update
- Fix String index problems

### Enhancements
- Support `greaterThan`, `lessThan` and `between` queries for String values
- Support for inheritance (enabled by default)
- Support for `final` properties and getters
- Support for `freezed` and other code generators
- Support getting / deleting objects by a key `col.deleteByName('Anne')`
- Support for list indexes (hash an element based)
- Generator now creates individual files instead of one big file
- Allow specifying the collection accessor name
- Unsupported properties are now ignored automatically
- Returns the assigned ids after `.put()` operations (objects are no longer mutated)
- Introduces `replaceOnConflict` option for `.put()` (instead of specifying it for index)
- many more...

### Internal
- Improve generated code
- Many new unit tests

## 0.4.0

### Breaking
- Remove `.where...In()` and `...In()` extension methods
- Split `.watch(lazy: bool)` into `.watch()` and `.watchLazy()`
- Remove `include` option for filters

### Fixes
- Generate id for JSON imports that don't have an id
- Enable `sortBy` and `thenBy` generation

### Enhancements
- Add `.optional()` and `.repeat()` query modifiers
- Support property queries
- Support query aggregation
- Support dynamic queries (for custom query languages)
- Support multi package configuration with `@ExternalCollection()`
- Add `caseSensitive` option to `.distinctBy()`

### Internal
- Change iOS linking
- Improve generated code
- Set up integration tests and improve unit tests
- Use CORE/0.4.0

## 0.2.0
- Link support
- Many improvements and fixes

## 0.1.0
- Support for links and backlinks

## 0.0.4
- Bugfixes and many improvements

## 0.0.2
Fix dependency issue

## 0.0.1
Initial release