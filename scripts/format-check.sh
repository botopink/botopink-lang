#!/usr/bin/env bash
# format-check.sh — `botopink format --check` over the compiler's own `.bp` trees.
# Decision 66: the scan looks at the whole project, and something has to call it;
# this is the caller, stage 3 of scripts/gate.sh and a step of CI's `test` job.
#
# TREES names the trees the gate holds canonical: every `.bp` and `.d.bp` under
# each (nested projects included). What the walk leaves out is structural —
# hidden directories, `node_modules`, `reject/<n>.bp` beside its `<n>.expect`,
# and a `modules/<cell>/` file the cell's `<target>.expect` files name that does
# not lex or parse (cli/format_cmd.zig, gate-c of specs/1.0.11-beta/00-gate). A
# red tree is a red gate: `botopink format <tree>` in a reformat-only commit
# fixes it. It is not a skip list, and there is no other way to exempt a file
# (decision 67). A tree whose reformat the printer cannot round-trip is a
# formatter defect (01-compiler/16-formatter), not a tree to list: today
# `tests/language/run` and `tests/language/test` — `run/record_update.bp`
# (`Cfg(..base, …)` printed as `Cfg(..: base, …)`) and `test/effect_result.bp`
# (a `try` inserted under parentheses) — join TREES when the printer round-trips
# them; `tests/language/modules` joins when the one cell whose `.expect` files
# pin a location the reformat moves (`decorator_imported_function_name_conflict`,
# `src/main.bp:17:3` → `:21:3`) has its four `.expect` lines moved with it and
# the file is reformatted (tests/language/AGENTS.md § 66); `libs/std` (19 files
# would reformat; its two `.d.bp` are canonical and listed) joins when the 26
# snapshots that quote std source verbatim — `compiler-core/snapshots/codegen/
# {beam,wat}/*/std_package_*` (24) and `language-server/snapshots/lsp/
# {definition_std_module_member,completion_array_methods}` (2) — are re-recorded
# in the same commit as its reformat (they differ by the quoted text alone).
#
# Usage: scripts/format-check.sh        (from anywhere in the checkout; needs `zig build`)
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
cd "$root"

bin="zig-out/bin/botopink"
[ -x "$bin" ] || bin="$bin.exe"
[ -x "$bin" ] || { echo "format-check: $bin is not built (run: zig build)" >&2; exit 1; }

TREES=(
    examples/generic-loader-binding
    examples/modules
    examples/stdlib-tour
    examples/yamlconf
    libs/std/src/builtins.d.bp
    libs/std/src/builtins_fns.d.bp
    libs/routing
    libs/actions
    libs/validation
    modules/compiler-cli/tests
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
