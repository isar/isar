## 4.0.0-dev.14

⚠️ ISAR V4 IS NOT READY FOR PRODUCTION USE ⚠️

This version does not support database migration yet and cannot open Isar v3 databases. The stable version will be released in a few weeks and will support migration from v3.

### Breaking

Changed transactions API:

| old              | new            |
| ---------------- | -------------- |
| `writeTxn()`     | `writeAsync()` |
| `writeTxnSync()` | `write()`      |
| `txn()`          | `readAsync()`  |
| `txnSync()`      | `read()`       |

- All operations are now synchronous by default and there are `Async` methods for asynchronous operations.
- Ids now need to be called `id` or annotated with `@id`
- Ids can no longer be `nullable`. There is a new `collection.autoIncrement()` function to automatically generate ids.
- Enums no longer need to be annotated with `@enumerated` instead there is a new `@enumValue` annotation to specify the value property of an enum
- Where clauses have been removed in favor of automatic index handling
- Isar links have been removed in favor of embedded objects
- Indexes have been simplified
- The Android minimum SDK version is now 23

### Enhancements

- Web support is back!!! In-memory only for now (persistence will come soon)
- Encrypted databases
- String ids
- Fetching multiple properties simultaneously
- Partial and Bulk updates using `collection.update()` and `query.updateAll()`
- SQLite storage engine support
- Support for `dynamic`, `List<dynamic>` and `Map<String, dynamic>` properties
- Required parameters for embedded objects
- Case insensitive sorting
- Much faster database initialization
- Improved performance for all operations
- Decoding objects no longer blocks the UI isolate
- New `@utc` annotation to receive `DateTime` objects in UTC
- Support for freezed and other code generators

## 3.1.0+1

### Fixes

- Fixed error building MacOS library

## 3.1.0

### Breaking

Sorry for this breaking change. Unfortunately, it was necessary to fix stability issues on Android.

- `directory` is now required for `Isar.open()` and `Isar.openSync()`

### Fixes

- Fixed a crash that occasionally occurred when opening Isar
- Fixed a schema migration issue
- Fixed an issue where embedded class renaming didn't work correctly

### Enhancements

- Many internal improvements
- Performance improvements

## 3.0.6

### Fixes

- Add check to verify transactions are used for correct instance
- Add check to verify that async transactions are still active
- Fix upstream issue with opening databases

## 3.0.5

### Enhancements

- Improved performance for all operations
- Added `maxSizeMiB` option to `Isar.open()` to specify the maximum size of the database file
- Significantly reduced native library size
- With the help of the community, the docs have been translated into a range of languages
- Improved API docs
- Added integration tests for more platforms to ensure high-quality releases
- Support for unicode paths on Windows

### Fixes

- Fixed crash while opening Isar
- Fixed crash on older Android devices
- Fixed a native port that was not closed correctly in some cases
- Added swift version to podspec
- Fixed crash on Windows
- Fixed "IndexNotFound" error

## 3.0.4

REDACTED.

## 3.0.3

REDACTED.

## 3.0.2

### Enhancements

- The Inspector now supports creating objects and importing JSON
- Added Inspector check to make sure Chrome is used

### Fixes

- Added support for the latest analyzer
- Fixed native ports that were not closed correctly in some cases
- Added support for Ubuntu 18.04 and older
- Fixed issue with aborting transactions
- Fixed crash when invalid JSON was provided to `importJsonRaw()`
- Added missing `exportJsonSync()` and `exportJsonRawSync()`
- Fixed issue where secondary instance could not be selected in the Inspector

## 3.0.1

### Enhancements

- Support for arm64 iOS Simulators

### Fixes

- Fixed issue where `.anyOf()`, `.allOf()`, and `.oneOf()` could not be negated
- Fixed too low min-iOS version. The minimum supported is 11.0
- Fixed error during macOS App Store build

## 3.0.0

This release has been a lot of work! Thanks to everyone who contributed and joined the countless discussions. You are really awesome!

Special thanks to [@Jtplouffe](https://github.com/Jtplouffe) and [@Peyman](https://github.com/Viper-Bit) for their incredible work.

### Web support

This version does not support the web target yet. It will be back in the next version. Please continue using 2.5.0 if you need web support.

### Enhancements

- Completely new Isar inspector that does not need to be installed anymore
- Extreme performance improvements for almost all operations (up to 50%)
- Support for embedded objects using `@embedded`
- Support for enums using `@enumerated`
- Vastly improved Isar binary format space efficiency resulting in about 20% smaller databases
- Added `id`, `byte`, `short` and `float` typedefs
- `IsarLinks` now support all `Set` methods based on the Isar `Id` of objects
- Added `download` option to `Isar.initializeIsarCore()` to download binaries automatically
- Added `replace` option for indexes
- Added verification for correct Isar binary version
- Added `collection.getSize()` and `collection.getSizeSync()`
- Added `query.anyOf()` and `query.allOf()` query modifiers
- Support for much more complex composite index queries
- Support for logical XOR and the `.oneOf()` query modifier
- Made providing a path optional
- The default Isar name is now `default` and stored in `dir/name.isar` and `dir/name.isar.lock`
- On non-web platforms, `IsarLink` and `IsarLinks` will load automatically
- `.putSync()`, `.putAllSync()` etc. will now save links recursively by default
- Added `isar.getSize()` and `isar.getSizeSync()`
- Added `linksLengthEqualTo()`, `linksIsEmpty()`, `linksIsNotEmpty()`, `linksLengthGreaterThan()`, `linksLengthLessThan()`, `linksLengthBetween()` and `linkIsNull()` filters
- Added `listLengthEqualTo()`, `listIsEmpty()`, `listIsNotEmpty()`, `listLengthGreaterThan()`, `listLengthLessThan()`, `listLengthBetween()` filters
- Added `isNotNull()` filters
- Added `compactOnLaunch` conditions to `Isar.open()` for automatic database compaction
- Added `isar.copyToFile()` which copies a compacted version of the database to a path
- Added check to verify that linked collections schemas are provided for opening an instance
- Apply default values from constructor during deserialization
- Added `isar.verify()` and `col.verify()` methods for checking database integrity in unit tests
- Added missing float and double queries and an `epsilon` parameter

### Breaking changes

- Removed `TypeConverter` support in favor of `@embedded` and `@enumerated`
- Removed `@Id()` and `@Size32()` annotations in favor of the `Id` and `short` types
- Changed the `schemas` parameter from named to positional
- The maximum size of objects is now 16MB
- Removed `replaceOnConflict` and `saveLinks` parameter from `collection.put()` and `collection.putAll()`
- Removed `isar` parameter from `Isar.txn()`, `Isar.writeTxn()`, `Isar.txnSync()` and `Isar.writeTxnSync()`
- Removed `query.repeat()`
- Removed `query.sortById()` and `query.distinctById()`
- Fixed `.or()` instead of `.and()` being used implicitly when combining filters
- Renamed multi-entry where clauses from `.yourListAnyEqualTo()` to `.yourListElementEqualTo()` to avoid confusion
- Isar will no longer create the provided directory. Make sure it exists before opening an Isar Instance.
- Changed the default index type for all `List`s to `IndexType.hash`
- Renamed `isar.getCollection()` to `isar.collection()`
- It is no longer allowed to extend or implement another collection
- Unsupported properties will no longer be ignored by default
- Renamed the `initialReturn` parameter to `fireImmediately`
- Renamed `Isar.initializeLibraries()` to `Isar.initializeIsarCore()`

### Fixes

There are too many fixes to list them all.

- A lot of link fixes and a slight behavior change to make them super reliable
- Fixed missing symbols on older Android phones
- Fixed composite queries
- Fixed various generator issues
- Fixed error retrieving the id property in a query
- Fixed missing symbols on 32-bit Android 5 & 6 devices
- Fixed inconsistent `null` handling in json export
- Fixed default directory issue on Android
- Fixed different where clauses returning duplicate results
- Fixed hash index issue where multiple list values resulted in the same hash
- Fixed edge case where creating a new index failed

## 2.5.0

### Enhancements

- Support for Android x86 (32 bit emulator) and macOS arm64 (Apple Silicon)
- Greatly improved test coverage for sync methods
- `col.clear()` now resets the auto increment counter to `0`
- Significantly reduced Isar Core binary size (about 1.4MB -> 800KB)

### Minor Breaking

- Changed `initializeLibraries(Map<String, String> libraries)` to `initializeLibraries(Map<IsarAbi, String> libraries)`
- Changed min Dart SDK to `2.16.0`

### Fixes

- Fixed issue with `IsarLink.saveSync()`
- Fixed `id` queries
- Fixed error thrown by `BroadcastChannel` in Firefox
- Fixed Isar Inspector connection issue

## 2.4.0

### Enhancements

- Support for querying links
- Support for filtering and sorting links
- Added methods to update and count links without loading them
- Added `isLoaded` property to links
- Added methods to count the number of objects in a collection
- Big internal improvements

### Minor Breaking

- There are now different kinds of where clauses for dynamic queries
- `isar.getCollection()` no longer requires the name of the collection
- `Isar.instanceNames` now returns a `Set` instead of a `List`

### Fixes

- Fixed iOS crash that frequently happened on older devices
- Fixed 32bit issue on Android
- Fixed link issues
- Fixed missing `BroadcastChannel` API for older Safari versions

## 2.2.1

### Enhancements

- Reduced Isar web code size by 50%
- Made `directory` parameter of `Isar.open()` optional for web
- Made `name` parameter of `Isar.getInstance()` optional
- Added `Isar.defaultName` constant
- Enabled `TypeConverter`s with supertypes
- Added message if `TypeConverter` nullability doesn't match
- Added more tests

### Fixes

- Fixed issue with date queries
- Fixed `FilterGroup.not` constructor (thanks for the PR @jtzell)

## 2.2.0

Isar now has full web support 🎉. No changes to your code required, just run it.

_Web passes all unit tests but is still considered beta for now._

### Minor Breaking

- Added `saveLinks` parameter to `.put()` and `.putAll()` which defaults to `false`
- Changed default `overrideChanges` parameter of `links.load()` to `true` to avoid unintended behavior

### Enhancements

- Full web support!
- Improved write performance
- Added `deleteFromDisk` option to `isar.close()`
- Added `.reset()` and `.resetSync()` methods to `IsarLink` and `IsarLinks`
- Improved `links.save()` performance
- Added many tests

### Fixed

- Fixed value of `null` dates to be `DateTime.fromMillisecondsSinceEpoch(0)`
- Fixed problem with migration
- Fixed incorrect list values for new properties (`[]` instead of `null`)
- Improved handling of link edge-cases

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
- Improved Isar Core error messages
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
