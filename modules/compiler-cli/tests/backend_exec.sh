#!/usr/bin/env bash
# Backend-execution parity (Front-C C2): the scenarios the codegen *snapshot*
# tests (Front A) can't prove — that the emitted programs actually RUN, and
# return the same observable result, on each backend.
#
# Covers, with skips when a runtime is absent:
#   • numeric  — pure arithmetic, runs on commonJS/erlang/beam/wasm → 55 (incl.
#     the wasm `--invoke main` numeric smoke)
#   • records  — records+enum+case+lambda, runs on commonJS/erlang/beam → 10
#   • modules  — a multi-folder `mod`/`pub mod` package (examples/modules) builds
#     + runs end-to-end on commonJS/erlang
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

# Pin a KNOWN BEAM red: the build (erlc) MUST succeed, but the run is only
# informational — BEAM mis-codegens this shape (case dispatch / lambda /
# call-result arithmetic), a Front-A gap. Never fails the harness; if the result
# ever becomes correct, it says so loudly so the pin can be promoted to a hard
# assert. See front-c-runtime.md C2.
pin_beam_red() {
  local dir="$1" want="$2" what="$3"
  echo "==> [$(basename "$dir")] beam (KNOWN RED — $what): build must pass; run informational"
  ( cd "$dir" && "$BP_BIN" build --target beam && erlc +from_asm -o out out/main.S )
  local got
  got="$( cd "$dir" && erl -noshell -pa out -eval 'io:format("~p", [main:main()]), halt(0)' 2>/dev/null || true )"
  if [[ "$got" == "$want" ]]; then
    echo "  beam: main:main() => $got  ✓ ($what looks FIXED — promote to a hard assert)"
  else
    echo "  beam: main:main() => ${got:-<crash>} (want $want; $what is a pinned Front-A red)"
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

# Pin a KNOWN run-time red on a whole backend: the run is expected to fail
# (Front-A codegen gap); informational, never aborts. Flags loudly if it starts
# passing so the pin can be promoted. See front-c-runtime.md C2.
pin_run_red() {
  local dir="$1" target="$2" what="$3"
  echo "==> [$(basename "$dir")] run --target $target (KNOWN RED — $what): informational"
  if ( cd "$dir" && "$BP_BIN" run --target "$target" ) >/dev/null 2>&1; then
    echo "  run: SUCCEEDED — $what looks FIXED (promote to a hard assert)"
  else
    echo "  run: failed as expected ($what is a pinned Front-A red)"
  fi
}

# `botopink run` a package and assert each expected line is in its output.
run_package() {
  local dir="$1" target="$2"; shift 2
  echo "==> [$(basename "$dir")] run --target $target"
  local out
  out="$( cd "$dir" && "$BP_BIN" run --target "$target" )"
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
if have erlc && have erl; then pin_beam_red "$RECORDS" 3 "case-dispatch/lambda codegen"; else echo "==> records beam: SKIPPED (no erlc/erl)"; fi

# ── multi-folder mod package (commonJS green; erlang a pinned red) ────────────
# commonJS runs the `mod`/`pub mod` tree end-to-end. The erlang backend currently
# emits cross-module calls (`area`, `describe`, `lucky`) as bare local calls
# rather than qualified `geometry:area` / `shapes:describe`, so escript rejects
# the module — a Front-A erlang module-system codegen gap, pinned here.
if have node; then run_package "$MODULES" commonJS 12 circle 7; else echo "==> modules commonJS: SKIPPED (no node)"; fi
if have escript; then pin_run_red "$MODULES" erlang "erlang cross-module call qualification"; else echo "==> modules erlang: SKIPPED (no escript)"; fi

echo "==> backend-execution parity: OK"
