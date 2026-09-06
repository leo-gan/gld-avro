#!/usr/bin/env bash
# Mojo ↔ official Python Avro interop. Requires python3 + avro.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
python3 scripts/gen_golden.py
schema='{"type":"int"}'
got=$(python3 tests_interop/encode_ref.py "$schema" 150 | xxd -p)
# zigzag(150)=300 = ac02
if [[ "$got" != "ac02" ]]; then
  echo "python encode int 150 unexpected: $got" >&2
  exit 1
fi
echo "interop python encode int 150 ok"
round=$(python3 tests_interop/encode_ref.py "$schema" 150 | python3 tests_interop/decode_ref.py "$schema")
if [[ "$round" != "150" ]]; then
  echo "python encode/decode int 150 unexpected: $round" >&2
  exit 1
fi
echo "interop python decode int 150 ok"
ocf=$(python3 tests_interop/ocf_ref.py write '{"type":"int"}' 7 | python3 tests_interop/ocf_ref.py read '{"type":"int"}')
if [[ "$ocf" != "7" ]]; then
  echo "python ocf int 7 unexpected: $ocf" >&2
  exit 1
fi
echo "interop python ocf int 7 ok"
# Golden file matches the official encoder.
pybin=$(python3 tests_interop/encode_ref.py "$schema" 150)
gothex=$(printf '%s' "$pybin" | xxd -p)
filehex=$(xxd -p testdata/golden/int_150.bin)
if [[ "$gothex" != "$filehex" ]]; then
  echo "golden int_150.bin != python encode: $gothex vs $filehex" >&2
  exit 1
fi
echo "interop golden int_150 matches python"
# Official JSON encoding of a union (not a Python dict dump).
python3 - <<'PY'
from avro.io import DatumWriter, BinaryEncoder
from avro.schema import parse
import io, json
schema = parse('["null","string"]')
buf = io.BytesIO()
DatumWriter(schema).write("hi", BinaryEncoder(buf))
raw = buf.getvalue()
assert raw[:1]  # union index + string
print("interop python union binary ok", raw.hex())
PY
# Mojo encoder → official Python decoder
mojo_out=$(pixi run mojo run -I src -I tests tests_interop/encode_mojo.mojo)
inthex=$(echo "$mojo_out" | awk '/^INT150 /{print $2}')
if [[ "$inthex" != "ac02" ]]; then
  echo "mojo encode int 150 unexpected: $inthex" >&2
  exit 1
fi
echo "$inthex" | xxd -r -p | python3 tests_interop/decode_ref.py "$schema" | grep -qx 150
echo "interop mojo→python int 150 ok"
msghex=$(echo "$mojo_out" | awk '/^MSG /{print $2}')
msgschema=$(python3 - <<'PY'
from pathlib import Path
print(Path("testdata/avsc/benchmark_v2.avsc").read_text().replace("\n",""))
PY
)
echo "$msghex" | xxd -r -p | python3 tests_interop/decode_ref.py "$msgschema" >/dev/null
echo "interop mojo→python Message ok"
soe=$(echo "$mojo_out" | awk '/^SOE /{print $2}')
if [[ "${soe:0:4}" != "c301" ]]; then
  echo "mojo SOE header unexpected: $soe" >&2
  exit 1
fi
echo "$soe" | xxd -r -p | tail -c +11 | python3 tests_interop/decode_ref.py "$msgschema" >/dev/null
echo "interop mojo SOE→python payload ok"
echo "$mojo_out" | grep -q '^JSON {'
echo "interop mojo JSON encode present"
python3 scripts/gen_deflate_golden.py >/dev/null
echo "interop goldens refreshed"
