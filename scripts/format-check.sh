#!/usr/bin/env bash
# format-check.sh — `botopink format --check` over the compiler's own `.bp` trees.
# Decision 66: the scan looks at the whole project, and something has to call it;
# this is the caller, stage 3 of scripts/gate.sh and a step of CI's `test` job.
#
# TREES names the trees the gate holds canonical: every `.bp` and `.d.bp` under
# each (nested projects included) — `examples` (every example project and
# `hello.bp`), `libs/std` and the four bundled libraries, the CLI's and the
# manifest module's fixtures and `tests/language` — every tracked `.bp` of this
# checkout is under one of them. What
# the walk leaves out is structural — hidden directories, `node_modules`,
# `reject/<n>.bp` beside its `<n>.expect`, and a `modules/<cell>/` file the
# cell's `<target>.expect` files name that does not lex or parse
# (cli/format_cmd.zig, gate-c of specs/1.0.11-beta/00-gate: under
# `tests/language` that is every `reject/` cell and
# `modules/lexer_error_in_imported_module/src/pattern.bp`). A red tree is a red
# gate: `botopink format <tree>` in a reformat-only commit fixes it. It is not
# a skip list, and there is no other way to exempt a file (decision 67). A tree
# whose reformat the printer cannot round-trip is a formatter defect
# (01-compiler/16-formatter), fixed in the printer — never a tree to leave out.
#
# A reformat that moves a text something else quotes carries that with it, in
# the same commit: `libs/std`'s source is quoted verbatim by the
# `compiler-core/snapshots/codegen/{beam,wat}/*/std_package_*` snapshots and two
# of `language-server/snapshots/lsp/` (re-recorded, differing by the quoted
# text alone), and a `modules/<cell>/<target>.expect` pins a `<file>:<L>:<C>`
# the reformat of that file can move.
#
# Usage: scripts/format-check.sh        (from anywhere in the checkout; needs `zig build`)
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
cd "$root"

bin="zig-out/bin/botopink"
[ -x "$bin" ] || bin="$bin.exe"
[ -x "$bin" ] || { echo "format-check: $bin is not built (run: zig build)" >&2; exit 1; }

TREES=(
    examples
    libs/std
    libs/routing
    libs/actions
    libs/validation
    libs/log
    modules/compiler-cli/tests
    modules/manifest/tests
    tests/language
)

status=0
for tree in "${TREES[@]}"; do
    if out="$("$bin" format --check "$tree" 2>&1)"; then
        printf '  ✓ %s\n' "$tree"
    else
        printf '%s\n' "$out" | grep -vE '^\s*(\x1b\[[0-9;]*m)?Unchanged' >&2 || true
        printf '  ✗ %s (run: %s format %s)\n' "$tree" "$bin" "$tree" >&2
        status=1
    fi
done
exit "$status"
