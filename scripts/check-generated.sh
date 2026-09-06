#!/usr/bin/env bash
# Fail if generated Mojo is out of date.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
if command -v mojo >/dev/null 2>&1; then
  MOJO=(mojo)
else
  MOJO=(pixi run mojo)
fi
"${MOJO[@]}" run -I src src/codegen/cli.mojo -- --schema testdata/avsc/benchmark_v2.avsc --out "$tmp"
if ! diff -u tests/generated/Message.mojo "$tmp/Message.mojo"; then
  echo "generated Message.mojo is stale; run scripts/generate.sh" >&2
  exit 1
fi
echo "generated sources match"
