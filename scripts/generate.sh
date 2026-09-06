#!/usr/bin/env bash
# Generate testdata schemas into tests/generated/.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"
mkdir -p tests/generated
if [[ -x .pixi/envs/default/bin/mojo ]]; then
  MOJO=(.pixi/envs/default/bin/mojo)
elif command -v pixi >/dev/null 2>&1; then
  MOJO=(pixi run mojo)
else
  MOJO=(mojo)
fi
"${MOJO[@]}" run -I src src/codegen/cli.mojo -- --schema testdata/avsc/benchmark_v2.avsc --out tests/generated
