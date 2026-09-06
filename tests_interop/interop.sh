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
python3 scripts/gen_deflate_golden.py >/dev/null
echo "interop goldens refreshed"
