# Instructions

## Install Mojo 1.0.0

```bash
git clone https://github.com/leo-gan/gld-avro.git
cd gld-avro
pixi install
pixi run test
```

If `pixi install` fails with 401 on `conda.modular.com`, set `PREFIX_API_KEY`
and run `scripts/ci-setup.sh`.

The published package is `mojo-avro` on
[prefix.dev/leo-gan/leo-gan](https://prefix.dev/leo-gan/leo-gan):

```bash
pixi add --channel https://prefix.dev/leo-gan/leo-gan mojo-avro
```

## Write a schema

A schema is the type definition for every Avro value. You write it once. The
generator turns it into a Mojo struct. The runtime also parses the same text
at decode time when you use `GenericDatum` or schema resolution.

Avro has two ways to write the **same** type system. They are not two
encodings. Binary bytes, Object Container Files, and Avro JSON encoding do
not care which file you authored. After parse, this library holds one
`SchemaPool` and the generator emits the same Mojo.

| File | Official name | Role |
| --- | --- | --- |
| `.avsc` | Avro JSON schema | The schema language in the spec. A JSON string, array, or object. |
| `.avdl` | Avro IDL | A Java-like authoring language. People write it; tools compile it to JSON. |
| `.avpr` | Avro protocol JSON | Compiled IDL: a `protocol` object with a `types` array and optional RPC `messages`. |

`.avsc` exists because the specification *is* JSON. OCF metadata key
`avro.schema`, Parsing Canonical Form, and the CRC-64-AVRO fingerprint are
all computed from that JSON (or its canonical form), not from IDL text.

`.avdl` exists because JSON is noisy for a large protocol: nested quotes,
repeated `"type"` keys, and no `import` story that reads like source code.
IDL gives `record`, `enum`, `fixed`, `T?` for a nullable, field defaults as
literals, and `import schema` / `import idl` / `import protocol`. A
`protocol` block can also declare RPC `message`s. This library parses the
data types and skips those RPC bodies.

This library's path is: `.avdl` → JSON schema → the same parser as `.avsc` →
the same emitter. `--schema` starts at the JSON file. `--idl` starts at the
IDL file. You do not keep two sources of truth for one type. Pick one file
to edit.

Use `.avsc` when the schema is the artifact you store or send (files, OCF
headers, other languages' `parse`). Use `.avdl` when you already have IDL
or you prefer the compact syntax. Start with `.avsc` unless you already have
an IDL file.

| Topic | `.avsc` | `.avdl` |
| --- | --- | --- |
| Syntax | JSON | IDL (`record Name { … }`) |
| Optional field | `["null", "T"]` | `T?` |
| Field default | JSON (`false`, `0`, `null`) | IDL literal (`false`, `0`, `null`) |
| Namespace | `"namespace": "…"` on the object | `@namespace("…")` |
| Sharing types | Nested JSON, or a JSON array of declarations | `import schema` / `import idl` / `import protocol` |
| RPC | Not in a schema file | `message` in a `protocol` (this library skips the body) |
| What OCF stores | This JSON (or equivalent) | Not the `.avdl` text |

A JSON-schema record is a named object with ordered fields:

```json
{
  "type": "record",
  "name": "Message",
  "namespace": "benchmark.v2",
  "fields": [
    {"name": "f_bool", "type": "boolean", "default": false},
    {"name": "f_int32", "type": "int", "default": 0},
    {"name": "f_int64", "type": "long", "default": 0},
    {"name": "f_float64", "type": "double", "default": 0},
    {"name": "f_string", "type": "string", "default": ""}
  ]
}
```

`namespace` plus `name` is the fullname (`benchmark.v2.Message`). Field
`default` values are Avro JSON. A union whose first branch is `null` is how
Avro spells an optional field:

```json
{"name": "next", "type": ["null", "LongList"], "default": null}
```

This library maps `["null", "T"]` to Mojo `Optional[T]`. If `T` is the same
record, or another record that refers back, the field type is
`Optional[Box[T]]` so the struct has a finite size.

The same record in Avro IDL looks like this (`testdata/avdl/message.avdl`):

```text
@namespace("benchmark.v2")
protocol Bench {
  record Message {
    boolean f_bool = false;
    int f_int32 = 0;
    long f_int64 = 0;
    double f_float64 = 0;
    string f_string = "";
  }
}
```

`T?` in IDL is `["null", T]`. Field defaults are IDL literals (including
`[1, 2]`, `{ k: "v" }`, and `{ field = value }`); the parser stores Avro JSON.
An `error` declaration is a record with `is_error` set. `import schema "path"`
reads a `.avsc` file. `import idl "path"` reads another `.avdl`.
`import protocol "path"` reads a JSON `.avpr` and keeps `types`, not RPC
`messages`. `FileImportResolver` reads those paths relative to the including
file. A cyclic import is a `SchemaError`.

Checked-in examples live under `testdata/avsc/` and `testdata/avdl/`.

## Generate Mojo from a schema

The generator is `gld-avrogen-mojo`. After a conda install that name is on
`PATH`. In a git checkout, run the same program through Mojo:

```bash
pixi run mojo run -I src src/codegen/cli.mojo -- \
  --schema testdata/avsc/benchmark_v2.avsc --out tests/generated
```

IDL uses `--idl` instead of `--schema`:

```bash
pixi run mojo run -I src src/codegen/cli.mojo -- \
  --idl testdata/avdl/message.avdl --out tests/generated
```

| Flag | Meaning |
| --- | --- |
| `--out DIR` | Directory that receives the generated `.mojo` files (required) |
| `--schema FILE` | Parse `FILE` as Avro JSON schema (`.avsc`) |
| `--idl FILE` | Parse `FILE` as Avro IDL (`.avdl`) |

Give exactly one of `--schema` or `--idl`. `--schema` calls `parse_avsc`.
`--idl` calls `parse_avdl`, then the same emitter.

`pixi run generate` runs `scripts/generate.sh`, which regenerates
`tests/generated/Message.mojo` from `testdata/avsc/benchmark_v2.avsc`. Use
that when you edit the in-tree `Message` schema. `pixi run check-generated`
fails if that file is stale.

Each named record becomes one file under `--out`, named after the short
record name (`Message.mojo`). The struct implements `AvroDatum`. It has a
zero-arg initializer (Avro defaults, `None` for optional fields),
`schema_json`, `encode_to`, and `decode_from`. Compile generated files with
`-I src` (or the installed `avro.mojoc`) and `-I` pointing at `--out`.

```mojo
from avro import encode, decode
from Message import Message

var m = Message()
m.f_int32 = 150
var buf = encode(m)
var m2 = decode[Message](buf)
```

If you change a schema, run the generator again. Do not edit the generated
file by hand.

## Encode and decode

`from avro import …` resolves with `mojo run -I src` in a checkout, or from
`avro.mojoc` after the package is installed.

Resolution uses `decode_resolving[T](buf, writer_schema_json)`. Object Container
Files use `write_ocf` / `read_ocf[T]`. Single-object frames use
`encode_single_object`. Official Avro JSON uses `encode_json` / `decode_json`.

## Logical types

Avro logical types are annotations on an underlying primitive. Binary bytes
stay that primitive. The codecs convert and check the high-level value.

| Logical type | Underlying | Codec |
| --- | --- | --- |
| `decimal` | `bytes` or `fixed` | `encode_decimal` / `decode_decimal` (or `*_fixed`) |
| `uuid` | `string` | `encode_uuid` / `decode_uuid` |
| `date` | `int` days since 1970-01-01 | `encode_date` / `decode_date` |
| `time-millis` | `int` | `encode_time_millis` / `decode_time_millis` |
| `time-micros` | `long` | `encode_time_micros` / `decode_time_micros` |
| `timestamp-millis` / `local-timestamp-millis` | `long` | `encode_timestamp_millis` / `decode_timestamp_millis` |
| `timestamp-micros` / `local-timestamp-micros` | `long` | `encode_timestamp_micros` / `decode_timestamp_micros` |
| `duration` | `fixed` of size 12 | `encode_duration` / `decode_duration` |

`parse_avsc` stores `logicalType` on the schema node. `precision` and `scale`
(and any other unrecognized object key) land in leftover attributes. A
logical type that does not match its underlying type is stored and ignored,
as the spec requires. `GenericDatum` decode rejects an invalid `uuid` string
and out-of-range `time-millis` / `time-micros`.

In IDL, put `@logicalType("date")` on the field, before the type.

## Tests

```bash
pixi run test
```

Python `avro` is optional. It is the oracle for `scripts/gen_golden.py`.
