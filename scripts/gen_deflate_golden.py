#!/usr/bin/env python3
"""Python zlib raw DEFLATE → testdata/golden/deflate/ for Mojo inflate."""

from __future__ import annotations

import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "testdata" / "golden" / "deflate"


def write(name: str, raw: bytes) -> None:
    c = zlib.compressobj(wbits=-15)
    z = c.compress(raw) + c.flush()
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / f"{name}.in").write_bytes(raw)
    (OUT / f"{name}.deflate").write_bytes(z)
    (OUT / f"{name}.deflate.hex").write_text(z.hex(" ") + "\n", encoding="utf-8")
    print(name, "raw", len(raw), "z", len(z), z.hex())


def main() -> int:
    write("hello", b"hello")
    write("abc", b"abcabcabcabcabc")
    write("empty", b"")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
