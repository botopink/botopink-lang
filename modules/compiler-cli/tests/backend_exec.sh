#!/usr/bin/env bash
# The wasm core module's `--invoke main` contract (front C C2): a `wasi` build
# is a WASI preview 2 component (decision 334) whose `(core module $main …)`,
# printed on its own, runs under `wasmtime --invoke main` and returns what
# `main` returns — 55 for the numeric fixture's `sumTo(10, 0)`.
#
# The language half of this script — the numeric program (`55` on the four
# targets), records with an enum / `case` / a lambda, and the multi-folder
# `mod` / `pub mod` package — is conformance cells since 144 B-29 step H:
# `conformance/modules/tail/run/src/cases/tail_recursive_sum`, `record_enum_case_lambda` and
# `modules` (each on every target `botopink cell check` runs it on). What stays
# here is the CLI's: a `wasi` build is a component, and its core module runs
# on its own.
#
# Exit 0 = the core module returned 55.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# `zig build test-backends` sets BOTOPINK_SKIP_BUILD=1 (the CLI is already
# installed by the step's dependency) so we don't nest a `zig build` inside one.
if [[ -z "${BOTOPINK_SKIP_BUILD:-}" ]]; then
  echo "==> building botopink CLI"
  ( cd "$REPO_ROOT" && zig build )
fi
BP_BIN="$REPO_ROOT/zig-out/bin/botopink"
if [[ ! -x "$BP_BIN" ]]; then
  echo "error: CLI binary not found at $BP_BIN" >&2
  exit 1
fi
command -v wasmtime >/dev/null 2>&1 || { echo "error: wasmtime is not on PATH (decision 67: a missing runtime fails, it is never skipped)" >&2; exit 1; }

# The module's last line is the `  )` just before the shim's module.
core_module() {
  awk '
    /^  \(core module \$main$/ { inside = 1; print "(module"; next }
    inside && /^  \(core module \$p1_shim$/ { print ")"; exit }
    inside { if (held != "") print held; held = $0; sub(/ \(export "__bp_init"\)/, "", held) }
  ' "$1"
}

# The `wasmtime` flags the module's `botopink.needs` section asks for (decision
# 518; `codegen/wat/needs.zig` `wasmtimeArgs`): a GC module (front 164 s2) runs
# under `-W gc=y`, as `botopink run` runs it.
needs_flags() {
  local names
  names="$(grep -o '(@custom "botopink.needs" "[^"]*")' "$1" | sed 's/.*"botopink.needs" "//; s/")$//; s/\\0a/ /g')"
  for n in $names; do
    case "$n" in
      exceptions) printf '%s\n' -W exceptions=y ;;
      http) printf '%s\n' -S http ;;
      gc) printf '%s\n' -W gc=y ;;
      *) echo "error: unknown need '$n' in $1" >&2; exit 1 ;;
    esac
  done
}

NUMERIC="$SCRIPT_DIR/backend_exec/numeric"
echo "==> [numeric] wasm: build + wasmtime --invoke main"
( cd "$NUMERIC" && "$BP_BIN" build --target wasm )
head -1 "$NUMERIC/out/main.wat" | grep -qx '(component' || { echo "  wasm: out/main.wat is not a component" >&2; exit 1; }
core_module "$NUMERIC/out/main.wat" > "$NUMERIC/out/main.core.wat"
mapfile -t flags < <(needs_flags "$NUMERIC/out/main.core.wat")
got="$(wasmtime run "${flags[@]}" --invoke main "$NUMERIC/out/main.core.wat" 2>/dev/null | tail -1 | tr -d '[:space:]')"
if [[ "$got" == "55" ]]; then
  echo "  wasm: main() => $got"
else
  echo "  wasm: WRONG '$got' (expected 55)" >&2
  exit 1
fi

echo "==> backend execution: OK"
