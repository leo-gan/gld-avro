#!/usr/bin/env python3
"""Official Python Avro OCF read/write helper."""

from __future__ import annotations

import io
import json
import sys

from avro.datafile import DataFileReader, DataFileWriter
from avro.io import DatumReader, DatumWriter
from avro.schema import parse


def main() -> int:
    mode = sys.argv[1]
    if mode == "write":
        schema = parse(sys.argv[2])
        datum = json.loads(sys.argv[3])
        buf = io.BytesIO()
        w = DataFileWriter(buf, DatumWriter(), schema)
        w.append(datum)
        w.flush()
        sys.stdout.buffer.write(buf.getvalue())
        return 0
    schema = parse(sys.argv[2])
    r = DataFileReader(io.BytesIO(sys.stdin.buffer.read()), DatumReader(schema))
    for rec in r:
        json.dump(rec, sys.stdout)
        sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
