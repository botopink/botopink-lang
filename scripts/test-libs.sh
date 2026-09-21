#!/usr/bin/env bash
# test-libs.sh — compile and test every `.bp` library the checkout can see, per
# target, through `botopink-lib-test` (`zig build test-libs`).
#
# Usage:
#   scripts/test-libs.sh [<botopink-lib-test args>…]
#
# Discovery is the runner's: `libs/` (std) plus every sibling project under an
# ancestor's `repository/` (emilia, erika, jhonstart, onze, rakun, … in the meta
# workspace, or the repos CI checks out next to botopink-lang) — and every
# member of a workspace found there (a `botopink.json` with `"workspaces"`,
# decision 75): `repository/rakun/modules/*` and `examples/*` are cells by their
# own `name`, one row each, with no root export from this script.
#
# The run is reported cell by cell:
#   pass          the library compiled and every test passed
#   FAIL          a module did not compile or a test failed — the diagnostic is
#                 printed above the cell line
#   known red     FAIL on a cell listed in scripts/known-red-libs.txt, named with
#                 the front that owns the fix; counted, does not fail the run
#   restricted    the library's `targets` list excludes this target, so the
#                 cell is invisible to that library's own gate. It is run
#                 anyway (`--include-unsupported`) and its FAILED-test count
#                 is checked against scripts/restricted-targets.txt — the
#                 ledger that makes a restriction measured, not silent
#   skipped       the target is not runnable by `botopink test` at all
#   no tests      the library has no `test {}` block; its `.bp` sources were
#                 compiled (`botopink build`) and nothing ran — a compile
#                 error is a FAIL
#
# Exit codes:
#   0  every cell passed, was skipped, is a listed known red, or is a restricted
#      cell whose failed count is exactly what the ledger pins
#   1  a runtime pre-flight failed, an unlisted cell failed, a listed known red
#      passed (delete its line in scripts/known-red-libs.txt), or the ledger was
#      refused (the three refusals below)
#   N  the runner's own error exit (bad arguments, no library root)
#
# The restricted-targets ledger is strict in BOTH directions:
#   · a restricted cell with no ledger line   → FAIL: measure it, then write
#                                                the line. A new restriction
#                                                cannot enter silently.
#   · a ledger line whose cell no longer
#     restricts that target                   → FAIL: delete the line. (On a
#                                                run with no arguments, a line
#                                                with no cell at all is stale
#                                                too — the member is gone.)
#   · a pinned count that moved, UP or DOWN   → FAIL: a regression, or a fix
#                                                to bank by editing the number.
# Only the FAILED count is pinned, never the passed one: a library adding a
# green test moves nothing here, so an ordinary library commit never has to
# touch this repository.
#
# Pass `--json` to get the runner's raw JSONL instead (no known-red handling).
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

if [ -f repository/botopink-lang/build.zig ]; then
    core_dir="repository/botopink-lang"
elif [ -f build.zig ]; then
    core_dir="."
else
    echo "test-libs: build.zig not found at repository/botopink-lang or repo root" >&2
    exit 1
fi

runner="$core_dir/zig-out/bin/botopink-lib-test"
if [ ! -x "$runner" ]; then
    echo "test-libs: runner not built yet ($runner)" >&2
    echo "         → run \`zig build install\` in $core_dir first." >&2
    exit 1
fi

# Pre-flight env. Advisory: a missing runtime is warned about, and the cells
# that need it fail by name below — a partial environment still tests what it can.
need_warn() {
    local tool="$1" backend="$2" hint="$3"
    if ! command -v "$tool" >/dev/null 2>&1; then
        printf '\033[1;33mwarning:\033[0m %s missing — backend %s will fail.\n' "$tool" "$backend" >&2
        printf '         install hint: %s\n' "$hint" >&2
    fi
}

need_warn node "commonJS"        "https://nodejs.org/en/download (or your distro's package manager)"
need_warn escript "erlang/beam"  "apt-get install erlang (linux) · brew install erlang (macOS)"
need_warn erlc    "beam"         "apt-get install erlang (linux) · brew install erlang (macOS)"
need_warn wasmtime "wasm"        "curl https://wasmtime.dev/install.sh | bash"

for a in "$@"; do
    if [ "$a" = "--json" ]; then exec "$runner" "$@"; fi
done

# BOTOPINK_KNOWN_RED_LIBS overrides the list (used to test this script).
known_file="${BOTOPINK_KNOWN_RED_LIBS:-$core_dir/scripts/known-red-libs.txt}"
# known_owner <lib> <target> — prints "<owner> <reason>" for a listed cell.
known_owner() {
    [ -f "$known_file" ] || return 1
    awk -v lib="$1" -v target="$2" '
        /^[[:space:]]*(#|$)/ { next }
        $1 == lib && $2 == target { $1 = ""; $2 = ""; sub(/^[[:space:]]+/, ""); print; found = 1; exit }
        END { exit found ? 0 : 1 }
    ' "$known_file"
}

field() { # field <json-line> <key>
    sed -n "s/.*\"$2\":\"\([^\"]*\)\".*/\1/p" <<<"$1"
}

# BOTOPINK_RESTRICTED_TARGETS overrides the ledger (used to test this script).
ledger_file="${BOTOPINK_RESTRICTED_TARGETS:-$core_dir/scripts/restricted-targets.txt}"
# ledger_count <lib> <target> — prints the pinned failed count (a decimal, or
# the token `build` for a cell that does not compile). Exit 1 when unlisted.
ledger_count() {
    [ -f "$ledger_file" ] || return 1
    awk -v lib="$1" -v target="$2" '
        /^[[:space:]]*(#|$)/ { next }
        $1 == lib && $2 == target { print $3; found = 1; exit }
        END { exit found ? 0 : 1 }
    ' "$ledger_file"
}
# ledger_why <lib> <target> — prints "<owner> <reason>" for a listed cell.
ledger_why() {
    [ -f "$ledger_file" ] || return 1
    awk -v lib="$1" -v target="$2" '
        /^[[:space:]]*(#|$)/ { next }
        $1 == lib && $2 == target { $1 = ""; $2 = ""; $3 = ""; sub(/^[[:space:]]+/, ""); print; found = 1; exit }
        END { exit found ? 0 : 1 }
    ' "$ledger_file"
}
# ledger_cells — prints "<lib> <target>" for every ledger line, in file order.
ledger_cells() {
    [ -f "$ledger_file" ] || return 0
    awk '/^[[:space:]]*(#|$)/ { next } { print $1, $2 }' "$ledger_file"
}

# Bare (unquoted) JSON scalars. `field` reads string values; these read the
# `"restricted":true` / `"failed":0` / `"ran":true` keys the runner splices
# into every cell_summary. BRE only — no `\|` alternation, which BSD sed
# rejects; the key spelling is unique per record, so a greedy `.*` is safe.
jflag() { # jflag <json-line> <key> → true|false
    sed -n "s/.*\"$2\":\([a-z]*\).*/\1/p" <<<"$1"
}
jnum() { # jnum <json-line> <key> → decimal
    sed -n "s/.*\"$2\":\([0-9]*\).*/\1/p" <<<"$1"
}

passed=0; failed=0; known=0; skipped=0; no_tests=0; fixed=0; pinned=0
runner_exit=0
unexpected=""; promoted=""
# Ledger bookkeeping. `seen_restricted` / `seen_plain` are space-separated
# `<lib>#<target>` keys (no associative arrays — the macOS runner is bash 3.2).
seen_restricted=""; seen_plain=""
ledger_missing=""; ledger_moved=""; ledger_stale=""
# A run with no arguments covers every cell, so a ledger line with no cell at
# all is stale. A filtered run (--lib/--target/--filter) judges only what it ran.
full_run=0
[ $# -eq 0 ] && full_run=1

# The runner writes each cell's JSONL on stdout and the child's diagnostics on
# stderr, in order; merged, a cell's diagnostics precede its `cell_summary`.
set +e
while IFS= read -r line; do
    case "$line" in
        '{"lib":'*'"event":"test"'*)
            if [ "$(field "$line" status)" = "fail" ]; then
                printf '  FAIL test %s — %s (%s:%s)\n' "$(field "$line" name)" \
                    "$(field "$line" error_message)" "$(field "$line" error_file)" \
                    "$(sed -n 's/.*"error_line":\([0-9]*\).*/\1/p' <<<"$line")"
            fi
            ;;
        '{"lib":'*) ;; # per-cell test summary — the cell_summary carries the verdict
        '{"event":"cell_summary"'*)
            lib="$(field "$line" lib)"; target="$(field "$line" target)"
            status="$(field "$line" status)"
            restricted="$(jflag "$line" restricted)"
            ran="$(jflag "$line" ran)"; n_failed="$(jnum "$line" failed)"
            owner="$(known_owner "$lib" "$target")"; listed=$?
            # A cell the library's own `targets` list hides. It ran only because
            # this script passes --include-unsupported; its verdict belongs to
            # the ledger, not to the pass/FAIL tally or to known-red-libs.txt.
            # `skipped_unsupported` here means `botopink test` cannot run the
            # target at all (beam/wasm) — nothing was measured, so the ledger
            # asserts nothing about it, and the cell only counts as seen.
            if [ "$restricted" = "true" ] && [ "$status" != "skipped_unsupported" ]; then
                seen_restricted="$seen_restricted $lib#$target"
                # What the run measured. A cell that did not compile has NO
                # test tally ("ran":false) — it is `build`, never "0 failed":
                # reading a build red as green is the blindness this closes.
                measured="$n_failed"
                if [ "$status" = "fail" ] && { [ "$ran" != "true" ] || [ "$n_failed" = "0" ]; }; then
                    measured="build"
                fi
                if [ "$measured" = "build" ]; then
                    measured_text="does not build"
                else
                    measured_text="$measured failed"
                fi
                if pin="$(ledger_count "$lib" "$target")"; then
                    why="$(ledger_why "$lib" "$target")"
                    if [ "$pin" = "$measured" ]; then
                        pinned=$((pinned + 1))
                        printf '\033[33m── %s · %s: restricted — %s, as pinned (%s)\033[0m\n' \
                            "$lib" "$target" "$measured_text" "$why"
                    else
                        ledger_moved="$ledger_moved $lib·$target($pin→$measured)"
                        printf '\033[1;31m── %s · %s: restricted — pinned %s failed, measured %s (%s)\033[0m\n' \
                            "$lib" "$target" "$pin" "$measured" "$why"
                        printf '   → a pinned count moved. Fix the cell, or bank the new count in\n'
                        printf '     scripts/restricted-targets.txt — a move DOWN is banked, never ignored.\n'
                    fi
                else
                    ledger_missing="$ledger_missing $lib·$target($measured)"
                    printf '\033[1;31m── %s · %s: restricted, and not in the ledger\033[0m\n' "$lib" "$target"
                    printf '   → this cell measured: %s. Add a line to scripts/restricted-targets.txt:\n' "$measured_text"
                    printf '     %s %s %s <owner-front> <why the restriction exists>\n' "$lib" "$target" "$measured"
                fi
                continue
            fi
            if [ "$restricted" = "true" ]; then
                seen_restricted="$seen_restricted $lib#$target"
            else
                seen_plain="$seen_plain $lib#$target"
            fi
            case "$status" in
                pass)
                    if [ $listed -eq 0 ]; then
                        fixed=$((fixed + 1)); promoted="$promoted $lib·$target"
                        printf '\033[1;31m── %s · %s: PASS, but listed as a known red (%s)\033[0m\n' "$lib" "$target" "$owner"
                        printf '   → delete its line in scripts/known-red-libs.txt\n'
                    else
                        passed=$((passed + 1))
                        printf '\033[32m── %s · %s: pass\033[0m\n' "$lib" "$target"
                    fi
                    ;;
                fail)
                    if [ $listed -eq 0 ]; then
                        known=$((known + 1))
                        printf '\033[33m── %s · %s: known red — %s\033[0m\n' "$lib" "$target" "$owner"
                    else
                        failed=$((failed + 1)); unexpected="$unexpected $lib·$target"
                        printf '\033[1;31m── %s · %s: FAIL\033[0m\n' "$lib" "$target"
                    fi
                    ;;
                skipped_unsupported)
                    skipped=$((skipped + 1))
                    printf '── %s · %s: skipped — `botopink test` cannot run this target\n' "$lib" "$target"
                    ;;
                no_tests)
                    no_tests=$((no_tests + 1))
                    printf '── %s · %s: no tests — the library has no test {} block; its .bp sources, if any, compiled\n' "$lib" "$target"
                    ;;
            esac
            ;;
        '{"event":"run_summary"'*) ;;
        __runner_exit=*) runner_exit="${line#__runner_exit=}" ;;
        *) printf '%s\n' "$line" ;;
    esac
done < <("$runner" --json --include-unsupported "$@" 2>&1; echo "__runner_exit=$?")
set -e

# Refusal 2 — a stale ledger line. A line whose cell ran WITHOUT a restriction
# is stale by measurement: the member widened its `targets` and the line must
# go. On an unfiltered run a line with no cell at all is stale too (the member
# was renamed or deleted); a filtered run judges only the cells it ran.
while read -r l_lib l_target; do
    [ -n "$l_lib" ] || continue
    case " $seen_plain " in
        *" $l_lib#$l_target "*)
            ledger_stale="$ledger_stale $l_lib·$l_target"
            printf '\033[1;31m── %s · %s: a ledger line, but the member no longer restricts this target\033[0m\n' \
                "$l_lib" "$l_target"
            printf '   → delete its line in scripts/restricted-targets.txt; the cell is an ordinary assert now.\n'
            continue
            ;;
    esac
    case " $seen_restricted " in
        *" $l_lib#$l_target "*) continue ;;
    esac
    if [ "$full_run" -eq 1 ]; then
        ledger_stale="$ledger_stale $l_lib·$l_target"
        printf '\033[1;31m── %s · %s: a ledger line with no such cell in a full run\033[0m\n' \
            "$l_lib" "$l_target"
        printf '   → the member is gone or renamed; delete its line in scripts/restricted-targets.txt.\n'
    fi
done <<EOF
$(ledger_cells)
EOF

echo
printf 'test-libs: %d passed, %d failed, %d known red, %d restricted (pinned), %d skipped, %d without tests' \
    "$passed" "$failed" "$known" "$pinned" "$skipped" "$no_tests"
[ "$fixed" -gt 0 ] && printf ', %d known red now passing' "$fixed"
printf '\n'

if [ "$failed" -gt 0 ]; then
    echo "test-libs: FAILED cells:$unexpected" >&2
fi
if [ "$fixed" -gt 0 ]; then
    echo "test-libs: known reds that pass (delete them from scripts/known-red-libs.txt):$promoted" >&2
fi
if [ -n "$ledger_missing" ]; then
    echo "test-libs: restricted cells missing from scripts/restricted-targets.txt:$ledger_missing" >&2
fi
if [ -n "$ledger_moved" ]; then
    echo "test-libs: pinned failed counts that moved (pinned→measured):$ledger_moved" >&2
fi
if [ -n "$ledger_stale" ]; then
    echo "test-libs: stale lines in scripts/restricted-targets.txt:$ledger_stale" >&2
fi
if [ "$failed" -gt 0 ] || [ "$fixed" -gt 0 ] ||
    [ -n "$ledger_missing" ] || [ -n "$ledger_moved" ] || [ -n "$ledger_stale" ]; then
    exit 1
fi
# No cell failed but the runner still errored (bad args, no library root).
if [ "$passed$known$pinned$skipped$no_tests" = "00000" ] && [ "$runner_exit" != "0" ]; then
    exit "$runner_exit"
fi
exit 0
