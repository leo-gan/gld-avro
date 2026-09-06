#!/usr/bin/env bash
# Mojo ↔ official Python Avro interop. Requires python3 + avro.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
python3 scripts/gen_golden.py
echo "interop goldens refreshed"
