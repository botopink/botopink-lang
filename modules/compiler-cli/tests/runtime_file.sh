#!/usr/bin/env bash
# Decision 805 (1)–(3), 798 (5) — the build's reusable intermediate end to end
# against the real CLI, over `runtime_file/`: `app`, whose `main.bp` holds a
# decorator and a template of its dependency `lib`, a top-level `comptime`
# block, a folded value and a std module.
#   • `build --emit-runtime <dir>` writes `<dir>/<package>.bpr` per package —
#     `app.bpr`, `lib.bpr`, std's one per module under `std/` —, creating the
#     directory, each file named on stderr;
#   • on commonJS (with the `.d.ts`), erlang, beam and wasm, the program built
#     from `app.bpr` writes every file of the direct build, byte for byte, and
#     `run` from it prints what the direct `run` prints, nothing of the build
#     phase (the top-level block's `print`);
#   • the `.bpr` one target's build wrote builds every other target;
#   • a dependency's `.bpr` is the same bytes whichever build wrote it;
#   • refused: `build` / `run` over a `.bpr` without `--target`
#     (`runtime-target-required`), a `.bpr` of another compiler
#     (`runtime-other-compiler`), a dependency's `.bpr` as the program
#     (`runtime-not-a-program`), a package's `.bpr` missing beside the root's
#     (`runtime-missing`), `--emit-runtime` without its directory.
#
# BOTOPINK_BIN points the script at another binary. Exit 0 = every behaviour held.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

if [[ -z "${BOTOPINK_SKIP_BUILD:-}" && -z "${BOTOPINK_BIN:-}" ]]; then
  echo "==> building botopink CLI"
  ( cd "$REPO_ROOT" && zig build )
fi
BP_BIN="${BOTOPINK_BIN:-$REPO_ROOT/zig-out/bin/botopink}"
if [[ ! -x "$BP_BIN" ]]; then
  echo "error: CLI binary not found at $BP_BIN" >&2
  exit 1
fi

tmp_root="${TMPDIR:-/tmp}"
WORK="$(mktemp -d "${tmp_root%/}/botopink-runtime-file.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
cp -R "$SCRIPT_DIR/runtime_file/." "$WORK/"
APP="$WORK/app"

failures=0
fail() { echo "  ✗ $*" >&2; failures=$((failures + 1)); }

bp() { # <log> <args…>: the CLI in `app`, its stdout and stderr to <log>
  local log="$1"; shift
  ( cd "$APP" && "$BP_BIN" "$@" ) > "$log" 2>&1
}

# A refusal: exit 1 and the coded line.
refused() { # <what> <code> <args…>
  local what="$1" code="$2"; shift 2
  if bp "$WORK/refused.log" "$@"; then
    fail "$what: exit 0"
  elif ! grep -q "error\[$code\]" "$WORK/refused.log"; then
    fail "$what: no error[$code]"
    sed 's/^/      /' "$WORK/refused.log" >&2
  fi
}

RT="$WORK/rt"
for target in commonJS erlang beam wasm; do
  flags=()
  [[ "$target" == commonJS ]] && flags=(--typescript)
  rt="$RT-$target"
  if ! bp "$WORK/direct.log" build --target "$target" --out "$WORK/direct-$target" --emit-runtime "$rt" "${flags[@]}"; then
    fail "$target: the direct build failed"; sed 's/^/      /' "$WORK/direct.log" >&2; continue
  fi
  for f in app.bpr lib.bpr std/math.bpr; do
    [[ -f "$rt/$f" ]] || fail "$target: --emit-runtime wrote no $f"
    grep -q "wrote $rt/$f" "$WORK/direct.log" || fail "$target: --emit-runtime did not name $f"
  done
  if ! bp "$WORK/bpr.log" build --target "$target" --out "$WORK/bpr-$target" "${flags[@]}" "$rt/app.bpr"; then
    fail "$target: the build from app.bpr failed"; sed 's/^/      /' "$WORK/bpr.log" >&2; continue
  fi
  diff -r "$WORK/direct-$target" "$WORK/bpr-$target" > "$WORK/diff.log" \
    || { fail "$target: built from app.bpr differs from the direct build"; sed 's/^/      /' "$WORK/diff.log" >&2; }
  cmp -s "$RT-commonJS/lib.bpr" "$rt/lib.bpr" || fail "$target: lib.bpr differs from the one the commonJS build wrote"

  # `run`: the direct run prints the build phase, the run from the `.bpr` does not.
  bp "$WORK/run-direct.out" run --target "$target" --out "$WORK/run-direct-$target" || fail "$target: the direct run failed"
  grep -v -e 'Compiling' -e 'Compiled' -e '^build a$' "$WORK/run-direct.out" > "$WORK/want.out"
  grep -q '^build a$' "$WORK/run-direct.out" || fail "$target: the direct run printed no build output"
  # Any target from the `.bpr` the commonJS build wrote.
  bp "$WORK/run-bpr.out" run --target "$target" --out "$WORK/run-bpr-$target" "$RT-commonJS/app.bpr" || fail "$target: the run from app.bpr failed"
  diff "$WORK/want.out" "$WORK/run-bpr.out" > "$WORK/diff.log" \
    || { fail "$target: the run from app.bpr answers otherwise"; sed 's/^/      /' "$WORK/diff.log" >&2; }
done

refused "build over a .bpr without --target" runtime-target-required build "$RT-commonJS/app.bpr"
refused "run over a .bpr without --target" runtime-target-required run "$RT-commonJS/app.bpr"
cp "$RT-commonJS/app.bpr" "$WORK/foreign.bpr"
# The compiler's stamp: bytes 16–47 (after the two magics).
printf '\xff\xff\xff\xff' | dd of="$WORK/foreign.bpr" bs=1 seek=20 conv=notrunc 2>/dev/null
refused "a .bpr of another compiler" runtime-other-compiler build --target commonJS --out "$WORK/o" "$WORK/foreign.bpr"
refused "a dependency's .bpr as the program" runtime-not-a-program build --target commonJS --out "$WORK/o" "$RT-commonJS/lib.bpr"
mkdir -p "$WORK/lone" && cp "$RT-commonJS/app.bpr" "$WORK/lone/"
refused "a package's .bpr missing beside the root's" runtime-missing build --target commonJS --out "$WORK/o" "$WORK/lone/app.bpr"
if bp "$WORK/refused.log" build --emit-runtime; then fail "--emit-runtime without its directory: exit 0"; fi

if (( failures > 0 )); then
  echo "runtime_file.sh: $failures failure(s)" >&2
  exit 1
fi
echo "runtime_file.sh: every behaviour held"
