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

## Generate Mojo from a schema

```bash
pixi run mojo run -I src src/codegen/cli.mojo -- --schema testdata/avsc/benchmark_v2.avsc --out tests/generated
```

The CLI is `gld-avrogen-mojo` after a conda install.

## Encode and decode

```mojo
from avro import encode, decode
from Message import Message

var m = Message()
m.f_int32 = 150
var buf = encode(m)
var m2 = decode[Message](buf)
```

`from avro import …` resolves with `mojo run -I src` in a checkout, or from
`avro.mojoc` after the package is installed.

## Tests

```bash
pixi run test
```

Python `avro` is optional. It is the oracle for `scripts/gen_golden.py`.
