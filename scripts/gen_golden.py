#!/usr/bin/env python3
"""Write testdata/golden/* using official Python avro as the oracle."""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "testdata" / "golden"


def write_bin(name: str, data: bytes) -> None:
    GOLDEN.mkdir(parents=True, exist_ok=True)
    path = GOLDEN / name
    path.write_bytes(data)
    (GOLDEN / (name + ".hex")).write_text(data.hex(" ") + "\n", encoding="utf-8")
    print(f"{name}: {data.hex(' ')}")


def main() -> int:
    try:
        from avro.io import BinaryEncoder, DatumWriter
        from avro.schema import parse
        import io
    except ImportError:
        print("python avro not installed; writing zigzag-only goldens")
        # zigzag(150)=300 -> ac 02
        write_bin("int_150.bin", bytes([0xAC, 0x02]))
        write_bin("int_neg1.bin", bytes([0x01]))
        return 0

    schema = parse('{"type":"int"}')
    buf = io.BytesIO()
    DatumWriter(schema).write(150, BinaryEncoder(buf))
    write_bin("int_150.bin", buf.getvalue())
    buf = io.BytesIO()
    DatumWriter(schema).write(-1, BinaryEncoder(buf))
    write_bin("int_neg1.bin", buf.getvalue())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
