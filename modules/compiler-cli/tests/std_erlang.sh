#!/usr/bin/env bash
# Integration test: run the stdlib's own test suite on the Erlang backend.
#
#     bp test --target=erlang   (cwd = libs/std)
#
# This is an end-to-end test (it builds the `botopink` CLI and spawns
# `escript`), so it is NOT part of `zig build test` — run it directly:
#
#     bash modules/compiler-cli/tests/std_erlang.sh
#
# Exit 0 = the std suite compiled and every test passed on Erlang.
#
# NOTE (v0.beta.3): currently EXPECTED TO FAIL — the restructured stdlib uses
# interface/method dispatch (`n.abs()`, `xs.map(f)`, `Dict.empty()`) whose
# Erlang codegen is not implemented yet. See
# tasks/v0.beta.3/specs/stdlib-interface.md "Compiler integration". The test is
# committed now to pin the target behaviour and to flip green once that lands.
set -euo pipefail

# Resolve the repo root from this script's location (…/modules/compiler-cli/tests).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
STD_DIR="$REPO_ROOT/libs/std"

echo "==> building botopink CLI"
( cd "$REPO_ROOT" && zig build )

BP_BIN="$REPO_ROOT/zig-out/bin/botopink"
if [[ ! -x "$BP_BIN" ]]; then
  echo "error: CLI binary not found at $BP_BIN" >&2
  exit 1
fi

if ! command -v escript >/dev/null 2>&1; then
  echo "error: 'escript' (Erlang/OTP) not on PATH — required for --target=erlang" >&2
  exit 1
fi

echo "==> bp test --target=erlang  (cwd=$STD_DIR)"
cd "$STD_DIR"
exec "$BP_BIN" test --target erlang
