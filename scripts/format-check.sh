#!/usr/bin/env bash
# format-check.sh — `botopink format --check` over the compiler's own `.bp` trees.
# Decision 66: the scan looks at the whole project, and something has to call it;
# this is the caller, stage 3 of scripts/gate.sh and a step of CI's `test` job.
#
# TREES names the trees the gate holds canonical: every `.bp` and `.d.bp` under
# each (nested projects included; `reject/<n>.bp` beside its `<n>.expect` and
# hidden directories are structurally outside the walk — cli/format_cmd.zig). A
# tree joins the list when its last red lands; it is not a skip list, and there
# is no other way to exempt a file (decision 67). The trees that are red today
# are named below with their cause and the row that owns each, measured
# 2026-09-20 with the formatter at this commit:
#
#   libs/std                          src/path.bp:82 and src/querystring.bp:38 — method chains
#                                     decision 65 opens (C-14 / 09's reformat); src/builtins.d.bp:116
#                                     `fn await(self: Self) -> Result<T, E>;` does not parse
#                                     (C-11's parser defect — `await` as a method name, 01 step 11 / 08)
#   examples/generic-loader-binding   src/main.bp — two method chains (decision 65) → C-14
#   examples/stdlib-tour              src/main.bp — one method chain (decision 65) and two lambda
#                                     arguments that hug the call (decision 61 rule 1) → C-14
#   tests/language                    re-measured 2026-09-21 at `361d255d`: modules/* is **green** —
#                                     all 11 files, C-16 formatted them (decision 66's row) — and the
#                                     single-file cells are not: run/ 9 of 22, test/ 42 of 49. Two cells
#                                     do not parse — run/optional_null_pattern.bp:21 (`null` as a `case`
#                                     pattern) and test/case_arms.bp:21 (`1..9`, the named error
#                                     `pattern-range-exclusive`) — the suite's rows, not the formatter's
#                                     (front 12). The tree joins TREES when those two parse and the
#                                     single-file cells are reformatted
#   modules/compiler-cli/tests        5 fixtures written at two-space indent (backend_exec ×2,
#                                     mutual_recursion, test_tooling ×2) → 10-cli-residuals
#
# Usage: scripts/format-check.sh        (from anywhere in the checkout; needs `zig build`)
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
cd "$root"

bin="zig-out/bin/botopink"
[ -x "$bin" ] || bin="$bin.exe"
[ -x "$bin" ] || { echo "format-check: $bin is not built (run: zig build)" >&2; exit 1; }

TREES=(
    examples/modules
    libs/routing
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
