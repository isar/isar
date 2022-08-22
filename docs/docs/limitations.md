# Limitations

As you know, Isar works on mobile devices and desktops running on the VM as well as Web. Both platforms are very different and have different limitations.

## VM Limitations

- Only the first 1024 bytes of a string can be used for an prefix where clause

## Web Limitations

Because Isar Web relies on IndexedDB, there are more limitations but they are barely noticeable while using Isar.

- Currently, `Isar.splitWords()` and `.matches()` filters are not yet implemented
- Schema changes are not as tighly checked as in the VM so be careful to comply with the rules
- All number types are stored as double (the only js number type) so `@Size32` has no effect
- Indexes are represented differenlty so hash indexes don't use less space (they still work the same)
- `col.delete()` and `col.deleteAll()` work correctly but the return value is not correct
- `NaN` is not supported as a value
