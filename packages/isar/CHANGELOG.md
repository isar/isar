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