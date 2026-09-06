# mojo-avro

A from-scratch Apache Avro implementation for [Mojo](https://mojolang.org/).
The runtime and the code generator are written in Mojo. They do not wrap, link,
or vendor libavro, apache-avro-rs, or any other C, C++, or Rust Avro library.

Python `avro` is a **test oracle** for golden byte vectors. It is not required
to encode or decode at runtime.

This repository is a standalone library. It is not part of any other project.

Documentation: [leo-gan.github.io/gld-avro](https://leo-gan.github.io/gld-avro/).
That site has the install steps, schema-generation walkthrough, examples, and
test-data notes.

## Install

Published package (linux-64) on [prefix.dev/leo-gan/leo-gan](https://prefix.dev/leo-gan/leo-gan):

```bash
pixi add --channel https://prefix.dev/leo-gan/leo-gan mojo-avro
```

From a git checkout (development):

```bash
git clone https://github.com/leo-gan/gld-avro.git
cd gld-avro
pixi install
pixi run test
```

Requires **Mojo 1.0.0**.

## Generate Mojo from a schema

Write an [Avro](https://en.wikipedia.org/wiki/Apache_Avro) schema as JSON
(`.avsc`) or Avro IDL (`.avdl`). They describe the same types. `.avsc` is
the spec's JSON schema, which OCF and fingerprints actually store. `.avdl`
is a compact authoring language that this library compiles to that JSON.
Then run the generator. After a conda install the command is
`gld-avrogen-mojo`. In a checkout, call the same CLI through Mojo:

```bash
pixi run mojo run -I src src/codegen/cli.mojo -- \
  --schema testdata/avsc/benchmark_v2.avsc --out tests/generated
```

`--schema` reads `.avsc`. `--idl` reads `.avdl`. `--out` is the directory for
the generated `.mojo` files. `pixi run generate` rebuilds the in-tree
`Message` type from `testdata/avsc/benchmark_v2.avsc`.

How to write a schema, what the emitter emits, and how to import the result
are in [Instructions](https://leo-gan.github.io/gld-avro/instructions/).

## Layout

```text
src/wire/      # binary primitives
src/json/      # in-tree JSON tokenizer
src/schema/    # .avsc / .avdl / PCF / CRC-64-AVRO
src/deflate/   # raw RFC 1951
src/codegen/   # gld-avrogen-mojo
src/runtime/   # AvroDatum, GenericRecord, resolution, OCF, JSON, SOE
src/avro/      # public facade (`from avro import …`)
```

## License

MIT. Copyright (c) 2026 Leonid Ganeline.
