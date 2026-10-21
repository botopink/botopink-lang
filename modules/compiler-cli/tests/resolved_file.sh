#!/usr/bin/env bash
# Decisions 834 (1), (2), 835 (1), (3) — `--emit-resolved <dir>` against the real CLI, over
# `resolved_file/`: `app` (a root module `main`, a module `util` of its own
# package) over a dependency `lib` whose decorator and templates run at the
# build, and std's `math`.
#   • one file per module, grouped as the `.bpr` groups them:
#     `<dir>/app/main.bp`, `<dir>/app/util.bp`, `<dir>/lib/root.bp`,
#     `<dir>/lib/tools.bp`, `<dir>/std/math.bp`, each named on stderr and
#     opened by its `// module <path>` line; no `<dir>/app.bp`;
#   • every name as written, the imports kept: `util.bp` imports `greet`'s
#     module path as written; the expansion of `boxed`, which calls `lib`'s
#     private `wrap`, reaches it through its hygiene alias, printed as its
#     alias import, `wrap` declared in `lib/tools.bp`;
#   • what ran at build is gone with its import: `entity`, `shout`, `boxed`;
#   • a folded value the language cannot write is printed as the run-time call
#     that builds it (decision 835 (1)): a context, `createContext(v)`;
#   • a `@TypeInfo.all(…)` read stays the read as written (835 (3)).
# The printed tree re-read as a project, on every target, is the oracle of
# `compiler-core`'s `codegen/tests/resolved_print.zig` (its names are the
# compiler's, refused in a written program, 805 (6)).
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
WORK="$(mktemp -d "${tmp_root%/}/botopink-resolved-file.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
cp -R "$SCRIPT_DIR/resolved_file/." "$WORK/"
APP="$WORK/app"

failures=0
fail() { echo "  ✗ $*" >&2; failures=$((failures + 1)); }

RES="$WORK/res"
if ! ( cd "$APP" && "$BP_BIN" build --target commonJS --out "$WORK/out" --emit-resolved "$RES" ) > "$WORK/build.log" 2>&1; then
  fail "the build failed"; sed 's/^/      /' "$WORK/build.log" >&2
fi

for pair in app/main.bp:main app/util.bp:util lib/root.bp:lib/root lib/tools.bp:lib/tools std/math.bp:std/math; do
  f="${pair%%:*}" module="${pair#*:}"
  if [[ ! -f "$RES/$f" ]]; then fail "no $f"; continue; fi
  grep -q "wrote $RES/$f" "$WORK/build.log" || fail "$f not named on stderr"
  [[ "$(head -n 1 "$RES/$f")" == "// module $module" ]] || fail "$f does not open with '// module $module'"
done
[[ ! -e "$RES/app.bp" ]] || fail "a file per package: $RES/app.bp written"

has() { # <file> <text>
  grep -qF -- "$2" "$RES/$1" || { fail "$1 lacks: $2"; sed 's/^/      /' "$RES/$1" >&2; }
}
lacks() { # <file> <text>
  ! grep -qF -- "$2" "$RES/$1" || fail "$1 still holds: $2"
}
has app/main.bp 'import {util.greet};'
has app/main.bp 'pub mod util;'
has app/main.bp 'pub val loud = ("hello").toUpper();'
has app/util.bp 'import {tools.wrap as __bp_tpl_lib_tools__wrap} from "lib";'
has app/util.bp 'return __bp_tpl_lib_tools__wrap("hi") + Town.table();'
has lib/tools.bp 'fn wrap(text: string) -> string {'
lacks lib/tools.bp 'fn entity'
lacks lib/tools.bp 'fn shout'
lacks app/util.bp 'tools.entity'
lacks app/main.bp 'tools.shout'
has app/main.bp 'pub val prefix = createContext("#");'
lacks app/main.bp 'contextValue'
has app/main.bp 'val jobs: Declared<unknown>[] = @TypeInfo.all(with: job);'

if (( failures > 0 )); then
  echo "resolved_file.sh: $failures failure(s)" >&2
  exit 1
fi
echo "resolved_file.sh: every behaviour held"
