#!/usr/bin/env python3
"""Official Python Avro decoder (oracle). Schema JSON on argv, bytes on stdin."""

from __future__ import annotations

import json
import sys

from avro.io import BinaryDecoder, DatumReader
from avro.schema import parse


def main() -> int:
    schema = parse(sys.argv[1])
    dec = BinaryDecoder(sys.stdin.buffer)
    val = DatumReader(schema).read(dec)
    json.dump(val, sys.stdout)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
