# mojo-avro

A from-scratch Apache Avro implementation for [Mojo](https://mojolang.org/).
The runtime and the code generator are written in Mojo. They do not wrap, link,
or vendor libavro, apache-avro-rs, or any other C, C++, or Rust Avro library.

Python `avro` is a **test oracle** for golden byte vectors. It is not required
to encode or decode at runtime.

This repository is a standalone library. It is not part of any other project.

## Install

Published package (linux-64) on [prefix.dev/leo-gan/leo-gan](https://prefix.dev/leo-gan/leo-gan)
will be available after the first release:

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
