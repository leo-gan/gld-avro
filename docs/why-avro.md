# Why Avro

[Apache Avro](https://en.wikipedia.org/wiki/Apache_Avro) is a schema-first
binary format. Every value is written against a schema. The reader must have a
schema too. The two schemas do not have to be identical. Avro defines how a
writer schema is resolved against a reader schema.

This library implements that format in Mojo. It does not call libavro. Python
`avro` is used only as a test oracle.

## Binary encoding

Avro does not put field tags on the wire. Fields appear in schema order. Signed
integers use [ZigZag encoding](https://en.wikipedia.org/wiki/Variable-length_quantity#Zigzag_encoding)
followed by an unsigned varint. ZigZag maps a signed integer onto a non-negative
integer so small magnitudes, positive or negative, stay short on the wire. A
`null` value is zero bytes. A `boolean` is one byte, `0` or `1`. Strings and
bytes start with a `long` length.

Unions start with a `long` branch index, then the chosen value. The two-branch
form `["null", "T"]` is how Avro spells an optional field. This library maps that
form to Mojo `Optional[T]`. The encoder still writes the real schema index.

## Object Container Files

An `.avro` file starts with the four bytes `Obj1`, then a metadata map that
includes `avro.schema`, then a 16-byte sync marker. Data is stored in blocks.
Each block may be uncompressed (`null` codec) or raw DEFLATE (`deflate` codec).

## Single-object encoding

A single datum on the wire can carry its schema fingerprint. The frame is
`C3 01`, then the little-endian CRC-64-AVRO of the schema's Parsing Canonical
Form, then the binary datum.

## Avro JSON encoding

Avro also defines a JSON encoding. Unions (except `null`) are a single-key
object such as `{"string":"hi"}`. That is not a Python dict dump and not
Protocol Buffers JSON.
