#!/usr/bin/env bash
# Precompile published packages into /tmp/mojo-avro-pkg.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
out="${MOJO_AVRO_PKG:-/tmp/mojo-avro-pkg}"
mkdir -p "$out"
if command -v mojo >/dev/null 2>&1; then
  MOJO=(mojo)
else
  MOJO=(pixi run mojo)
fi
"${MOJO[@]}" precompile -I src src/wire -o "$out/wire.mojoc"
"${MOJO[@]}" precompile -I src src/json -o "$out/json.mojoc"
"${MOJO[@]}" precompile -I src src/deflate -o "$out/deflate.mojoc"
"${MOJO[@]}" precompile -I src src/schema -o "$out/schema.mojoc"
"${MOJO[@]}" precompile -I src src/runtime -o "$out/runtime.mojoc"
"${MOJO[@]}" precompile -I src src/avro -o "$out/avro.mojoc"
"${MOJO[@]}" build -I src src/codegen/cli.mojo -o "$out/gld-avrogen-mojo"
echo "wrote $out"
