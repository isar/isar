# Isar Binary Format Documentation

The Isar binary format is designed for efficient storage and quick random access to properties, with an emphasis on minimizing read operations. This document provides an overview of the format, its supported data types, and small examples to illustrate its usage.

A schema is employed to define properties and their associated data types. While new properties can be added to the schema, existing properties cannot be removed or altered.

## Data Types

The Isar binary format supports the following data types:

- Byte (`u8`)
- Int (`i32`)
- Long (`i64`)
- Float (`f32`)
- Double (`f64`)
- String
- Blob (byte array)
- Object (nested object)
- Json (any JSON value stored as a string)
- ByteList
- IntList
- LongList
- FloatList
- DoubleList
- StringList
- ObjectList

### Number Storage and Null Values

Numbers are stored in little-endian format. Booleans are stored as single bytes, with `0` representing `null`, `1` representing `false`, and `2` representing `true`.

For numeric data types, `null` values are represented by the minimum value for the corresponding type. For float and double data types, `NaN` is used to represent `null`.

**Example:** To store a `null` Int value, you would store the minimum value for an `i32`, which is `-2147483648` (in little-endian: `00 00 00 80`).

## Format Structure

The Isar binary format consists of two sections:

1. Static section
2. Dynamic section

All offsets within the format are relative to the start of the static section. An offset of 0 indicates a `null` value.

### Static Section

The static section begins with a header, which is a single `u16` value representing the size of the static section in bytes. This allows readers to determine the schema version used for serialization.

**Example:** If the static section is 20 bytes long, the header would be `14 00`.

Following the header, a value is stored for each property. Primitive values (Bool, Byte, Int, Long, Float, Double) are stored inline. Strings, blobs, and objects are stored as `u24` offsets pointing to the dynamic section.

**Example:** To store an Int value of `42`, you would store the bytes `2A 00 00 00` in the static section.

### Dynamic Section

The dynamic section contains the actual data for strings, blobs, objects, and lists.

- Strings and blobs: Stored as a `u24` value indicating the number of bytes, followed by the actual data.

  **Example:** To store the string "hello", first store the length `05 00 00` (5 bytes), followed by the actual data `68 65 6C 6C 6F`.

- Objects: Stored as a `u24` value indicating the number of bytes, followed by the serialized object (header, static, and dynamic data).

  **Example:** To store an object with two properties: a Byte (`true`) and an Int (`42`), first store the length of the serialized object in the dynamic section, in this case, `07 00 00` (7 bytes).  
  Next, store the header, `07 00`, representing the static section size of 7 bytes. In the static section, store the boolean property value `02` (for `true`) and the integer property value `2A 00 00 00`.  
  So the full serialized object would be `07 00 00 07 00 02 2A 00 00 00`.

- Lists: Stored as a `u24` value indicating the number of items, followed by the individual items. Primitive values are stored inline, whereas strings, blobs, and objects are stored as `u24` offsets.

  **Example:** To store an Int list containing the values `1, 2, 3`, first store the length `03 00 00` (3 items), followed by the individual values `01 00 00 00`, `02 00 00 00`, and `03 00 00 00`.

## Example

Suppose we want to store an object with the following properties:

- An Int property, `id`: 42
- A String property, `name`: "Alice"
- A Float list property, `scores`: [1.5, 2.0, 3.5]

### Static Section

1. Calculate the size of the static section:
   - Header (2 bytes) + Int (4 bytes) + Offset for String (3 bytes) + Offset for Float list (3 bytes) = 12 bytes
2. Write the header: `0C 00`
3. Write the Int value: `2A 00 00 00`
4. Write the offset for the string: `0C 00 00`
5. Write the offset for the float list: `15 00 00`

The static section would be: `0C 00 2A 00 00 00 0C 00 00 15 00 00`.

### Dynamic Section

1. Write the string:
   - Length: `05 00 00`
   - Data: `41 6C 69 63 65`
2. Write the float list:
   - Length: `03 00 00`
   - Data: `00 00 C0 3F 00 00 00 40 00 00 60 40`

The dynamic section would be: `05 00 00 41 6C 69 63 65 03 00 00 00 00 C0 3F 00 00 00 40 00 00 60 40`.
