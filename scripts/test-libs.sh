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
#   skipped       with the reason: the target is not runnable by `botopink
#                 test`, or the library's `targets` list excludes it
#   no tests      the library has no `test {}` block; its `.bp` sources were
#                 compiled (`botopink build`) and nothing ran — a compile
#                 error is a FAIL
#
# Exit codes:
#   0  every cell passed, was skipped, or is a listed known red
#   1  a runtime pre-flight failed, an unlisted cell failed, or a listed known
#      red passed (delete its line in scripts/known-red-libs.txt)
#   N  the runner's own error exit (bad arguments, no library root)
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

passed=0; failed=0; known=0; skipped=0; no_tests=0; fixed=0; runner_exit=0
unexpected=""; promoted=""

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
            owner="$(known_owner "$lib" "$target")"; listed=$?
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
                    printf '── %s · %s: skipped — `botopink test` cannot run this target, or the library'"'"'s "targets" list excludes it\n' "$lib" "$target"
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
done < <("$runner" --json "$@" 2>&1; echo "__runner_exit=$?")
set -e

echo
printf 'test-libs: %d passed, %d failed, %d known red, %d skipped, %d without tests' \
    "$passed" "$failed" "$known" "$skipped" "$no_tests"
[ "$fixed" -gt 0 ] && printf ', %d known red now passing' "$fixed"
printf '\n'

if [ "$failed" -gt 0 ]; then
    echo "test-libs: FAILED cells:$unexpected" >&2
fi
if [ "$fixed" -gt 0 ]; then
    echo "test-libs: known reds that pass (delete them from scripts/known-red-libs.txt):$promoted" >&2
fi
if [ "$failed" -gt 0 ] || [ "$fixed" -gt 0 ]; then exit 1; fi
# No cell failed but the runner still errored (bad args, no library root).
if [ "$passed$known$skipped$no_tests" = "0000" ] && [ "$runner_exit" != "0" ]; then
    exit "$runner_exit"
fi
exit 0
