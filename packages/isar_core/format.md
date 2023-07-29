# Isar Binary Format Documentation

The Isar binary format is designed to efficiently store objects and allow quick random access to properties, with an emphasis on minimizing read operations. This document provides an overview of the format, its supported data types, and small examples to illustrate its usage.

A schema is required to define properties and their associated data types. While new properties can be added to the schema, existing properties cannot be removed or altered.

All numeric values are stored in little-endian format. All offsets are `u24` integers relative to the start of the static section.

## Data Types

The Isar binary format supports the following data types:

- Byte (`u8`)
- Int (`i32`)
- Long (`i64`)
- Float (`f32`)
- Double (`f64`)
- Nested Object

### Number Storage and Null Values

Booleans are stored as single bytes, with `0` representing `false`, `1` representing `true`, and every other byte representing `null`.

For numeric data types, `null` values are represented by the minimum value for the corresponding type. For float and double data types, `NaN` is used to represent `null`.

**Example:** To store a `null` Int value, you would store the minimum value for an `i32`, which is `-2147483648` (in little-endian: `00 00 00 80`).

`null` values of nested data types are represented by an offset of `0`.

## Format Structure

The Isar binary format consists of three parts:

1. Static size
2. Static section
3. Dynamic section

All offsets within the format are relative to the start of the static section. An offset of 0 indicates a `null` value.

### Static Size

The first three bytes of the format are reserved for the static size. This allows readers to quickly determine the size of the static section, and thus the location of the dynamic section.
It also allows adding new properties to the schema without breaking existing data, as readers can skip over properties with an offset greater than the static size.

**Example:** If the static section is 20 bytes long, the static size would be `14 00 00`.

### Static Section

The static section contains primitive values (Bool, Byte, Int, Long, Float, Double) inline and offsets to the dynamic section for nested objects.

**Example:** To store an Int value of `42`, you would store the bytes `2A 00 00 00` in the static section.

### Dynamic Section

The dynamic section contains the actual data for all nested objects. Nested objects have the same structure as the top-level object, with a static section followed by an optional dynamic section.

Lists are stored like an object with n properties, where n is the number of elements in the list.

**Example** To store a Int list value of `[1, 2, 3]`, you would store the bytes `03 00 00` as static size followed by `01 00 00 00 02 00 00 00 03 00 00 00` in the static section.

Strings are stored like a list of bytes.

**Example:** To store a String value of `"Alice"`, you would store the bytes `05 00 00` as the static size followed by `41 6C 69 63 65` in the static section.

## Example

Suppose we want to store an object with the following properties:

- An Int property, `id`: 42
- A String property, `name`: "Alice"
- A Float list property, `scores`: [1.5, 2.0, 3.5]

### Static Section

1. Calculate the size of the static section:
   - Int (4 bytes) + Offset for String (3 bytes) + Offset for Float list (3 bytes) = 12 bytes
2. Write the static size: `0C 00 00`
3. Write the Int value: `2A 00 00 00`
4. Write the offset for the string: `0C 00 00`
5. Write the offset for the float list: `15 00 00`

The static section would be: `0C 00 00 2A 00 00 00 0C 00 00 15 00 00`.

### Dynamic Section

1. Write the string:
   - Static size: `05 00 00`
   - Static section: `41 6C 69 63 65`
2. Write the float list:
   - Static size: `03 00 00`
   - Static section: `00 00 C0 3F 00 00 00 40 00 00 60 40`

The dynamic section would be: `05 00 00 41 6C 69 63 65 03 00 00 00 00 C0 3F 00 00 00 40 00 00 60 40`.
