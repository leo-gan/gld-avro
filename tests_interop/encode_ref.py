#!/usr/bin/env python3
"""Official Python Avro encoder (oracle). Reads schema JSON + datum JSON from argv."""

from __future__ import annotations

import io
import json
import sys

from avro.io import BinaryEncoder, DatumWriter
from avro.schema import parse


def main() -> int:
    schema = parse(sys.argv[1])
    datum = json.loads(sys.argv[2])
    buf = io.BytesIO()
    DatumWriter(schema).write(datum, BinaryEncoder(buf))
    sys.stdout.buffer.write(buf.getvalue())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
