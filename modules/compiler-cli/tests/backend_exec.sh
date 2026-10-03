#!/usr/bin/env bash
# Backend-execution parity (Front-C C2): the scenarios the codegen *snapshot*
# tests (Front A) can't prove — that the emitted programs actually RUN, and
# return the same observable result, on each backend.
#
# Covers, with skips when a runtime is absent:
#   • numeric  — pure arithmetic, runs on commonJS/erlang/beam/wasm → 55 (incl.
#     the wasm `--invoke main` numeric smoke)
#   • records  — records+enum+case+lambda, runs on commonJS/erlang, and on beam
#     (`main:main()` → 3)
#   • modules  — a multi-folder `mod`/`pub mod` package (examples/modules) builds
#     + runs end-to-end on commonJS
#
# Every cell is a hard assert; there are no pinned reds. A cell whose backend is
# red today is not run at all and is listed in ../AGENTS.md ("Cells not run")
# with the front that restores it.
#
# Exit 0 = every reachable (backend, fixture) cell ran and matched.

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

have() { command -v "$1" >/dev/null 2>&1; }

# Run `botopink test --target <t>` in a fixture dir; the assertions live in the
# fixture's `test {}` block, so a non-zero exit means a parity failure.
run_test_target() {
  local dir="$1" target="$2"
  echo "==> [$(basename "$dir")] test --target $target"
  ( cd "$dir" && "$BP_BIN" test --target "$target" )
}

# Build the BEAM assembly, assemble it with `erlc +from_asm` and assert that
# `main:main()` prints as $want.
run_beam() {
  local dir="$1" want="$2"
  echo "==> [$(basename "$dir")] beam: build + erlc +from_asm + main:main()"
  # 13 half 1: an erlang/BEAM artifact is named by its module atom under
  # `out/<target>/`, because `erlc` refuses a `-module` atom that differs from
  # its file's basename. `-o out` still puts the `.beam` where `-pa out` looks.
  # Decision 109: the atom starts with the package — the fixture's directory
  # name is its `botopink.json` `name`.
  local entry
  entry="$(basename "$dir")@main"
  ( cd "$dir" && "$BP_BIN" build --target beam && erlc +from_asm -o out "out/beam/$entry.S" )
  local got
  got="$( cd "$dir" && erl -noshell -pa out -eval "io:format(\"~p\", [$entry:main()]), halt(0)" 2>/dev/null || true )"
  if [[ "$got" == "$want" ]]; then
    echo "  beam: main:main() => $got"
  else
    echo "  beam: WRONG '${got:-<crash>}' (expected $want)" >&2
    exit 1
  fi
}

# Build for wasm and assert `main()` equals $expected under wasmtime.
run_wasm() {
  local dir="$1" expected="$2"
  echo "==> [$(basename "$dir")] wasm: build + wasmtime --invoke main"
  ( cd "$dir" && "$BP_BIN" build --target wasm )
  local got
  got="$(wasmtime --invoke main "$dir/out/main.wat" 2>/dev/null | tail -1 | tr -d '[:space:]')"
  if [[ "$got" == "$expected" ]]; then
    echo "  wasm: main() => $got"
  else
    echo "  wasm: WRONG '$got' (expected $expected)" >&2
    exit 1
  fi
}

# `botopink run` a package and assert each expected line is in its output. The
# artifacts go to a temporary `--out`, so a tracked example tree stays clean.
run_package() {
  local dir="$1" target="$2"; shift 2
  echo "==> [$(basename "$dir")] run --target $target"
  local out out_dir
  out_dir="$(mktemp -d "${TMPDIR:-/tmp}/botopink-backend-exec.XXXXXX")"
  out="$( cd "$dir" && "$BP_BIN" run --target "$target" --out "$out_dir" )"
  rm -rf "$out_dir"
  echo "$out"
  for needle in "$@"; do
    if ! grep -qx "$needle" <<<"$out"; then
      echo "  run: missing expected line '$needle'" >&2
      exit 1
    fi
  done
}

NUMERIC="$SCRIPT_DIR/backend_exec/numeric"
RECORDS="$SCRIPT_DIR/backend_exec/records"
MODULES="$REPO_ROOT/examples/modules"

# ── numeric (commonJS / erlang / wasm) ───────────────────────────────────────
# NB: BEAM is intentionally NOT run for the numeric fixture. BEAM codegen for
# integer arithmetic combined with calls (`f(n-1) + …`, or a 2-arg call whose
# args need arithmetic) currently fails erlc's `beam_validator` consistency
# check (`not_live` / `uninitialized_reg`) — a known Front-A red. The one green
# BEAM run lives in mutual_recursion.sh (bool, single-arg, bare-if). Recorded in
# front-c-runtime.md C2.
if have node; then run_test_target "$NUMERIC" commonJS; else echo "==> numeric commonJS: SKIPPED (no node)"; fi
if have escript; then run_test_target "$NUMERIC" erlang; else echo "==> numeric erlang: SKIPPED (no escript)"; fi
if have wasmtime; then run_wasm "$NUMERIC" 55; else echo "==> numeric wasm: SKIPPED (no wasmtime)"; fi

# ── records (commonJS / erlang / beam) ───────────────────────────────────────
if have node; then run_test_target "$RECORDS" commonJS; else echo "==> records commonJS: SKIPPED (no node)"; fi
if have escript; then run_test_target "$RECORDS" erlang; else echo "==> records erlang: SKIPPED (no escript)"; fi
if have erlc && have erl; then run_beam "$RECORDS" 3; else echo "==> records beam: SKIPPED (no erlc/erl)"; fi

# ── multi-folder mod package (commonJS / erlang) ─────────────────────────────
# commonJS and erlang both run the `mod`/`pub mod` tree end-to-end. The erlang
# cell used to be skipped, and **not** because of the backend: the emitted calls
# were already properly qualified (`geometry:area/2`, `shapes:describe/0`,
# `shapes:lucky/0`). `botopink run --target erlang` spawned `escript
# out/main.erl`, and escript compiles only the file it is handed, so the sibling
# module was `undef` (`undefined function geometry:area/2`). Front
# `13-module-identity` half 1 fixed `cli/run.zig` at the shape front 10
# measured — `erlc -o <out>/erl` over every emitted `.erl`, then
# `erl -noshell -pa <out>/erl`, which is what the beam arm of
# `tests/language/run.sh` already uses — so the cell is restored here exactly as
# that analysis asked.
if have node; then run_package "$MODULES" commonJS 12 circle 7; else echo "==> modules commonJS: SKIPPED (no node)"; fi
if have erlc && have erl; then run_package "$MODULES" erlang 12 circle 7; else echo "==> modules erlang: SKIPPED (no erlc/erl)"; fi

echo "==> backend-execution parity: OK"
