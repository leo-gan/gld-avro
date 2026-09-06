# Test data

Test schemas and oracle bytes live under `testdata/`. They are ordinary unit-test
data. They are not the product schema.

| Path | Why it exists |
| --- | --- |
| `testdata/avsc/benchmark_v2.avsc` | Scalar record `Message` used by codegen and round-trip tests |
| `testdata/avsc/document.avsc` | Nested record, nullable `meta`, array of items |
| `testdata/avsc/longlist.avsc` | Recursive record; codegen emits `Optional[Box[LongList]]` |
| `testdata/avsc/mutual_ab.avsc` | Mutual `A` / `B` records (JSON array of declarations) |
| `testdata/avsc/node_union.avsc` | Record whose field is a tagged union that includes `Node` |
| `testdata/golden/` | Official-oracle byte vectors (`.bin` plus `.hex`) |
| `testdata/avdl/` | Avro IDL inputs for the IDL parser |
| `testdata/avpr/` | JSON protocol files; parser keeps `types`, ignores `messages` |

The v2 record shapes (`Message`, `Document`, `Telemetry`, `Strings`, `Event`)
match a common mixed-scalar set. They live in this repository only.
