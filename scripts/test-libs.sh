#!/usr/bin/env bash
# test-libs.sh — compile and test every `.bp` library the checkout can see, per
# target, through `botopink-lib-test` (`zig build test-libs`).
#
# Usage:
#   scripts/test-libs.sh [<botopink-lib-test args>…]
#
# The arguments go to the runner as given: `--lib` is repeatable, and every
# name runs, in the order given, in one report (decision 258); a `--lib` that
# names no library fails the run.
#
# Discovery is the runner's: `libs/` (std) plus every sibling project under an
# ancestor's `repository/` (emilia, erika, jhonstart, onze, rakun, … in the meta
# workspace, or the repos CI checks out next to botopink-lang) — and every
# member of a workspace found there (a `botopink.json` with `"workspaces"`,
# decision 75): `repository/rakun/modules/*` and `examples/*` are cells by their
# own `name`, one row each, with no root export from this script.
#
# The manifest decides the matrix. A member runs on the targets its
# `botopink.json` declares and on no other: a target its `"targets"` list
# excludes is not a cell. Nothing in this script or in the runner runs such a
# target or reads a list that says how red a cell may be — there is no ledger,
# no known-red file and no environment variable that changes a verdict
# (decision 67).
#
# The run is reported pair by pair:
#   pass          the library compiled and every test passed
#   FAIL          a module did not compile or a test failed — the diagnostic is
#                 printed above the cell line. A cell that exists is green or
#                 the run fails
#   no tests      the library has no `test {}` block; its `.bp` sources were
#                 compiled (`botopink build`) and nothing ran — a compile
#                 error is a FAIL
#   excluded      not a cell: the member's `"targets"` list excludes the target.
#                 The exclusion is AUDITED on every run — `botopink build
#                 --target <excluded>` must be refused, its first error the
#                 missing host binding (`has no #[@External.<Target>(…)]`). The
#                 line quotes the refusal that proves the exclusion structural
#   NOT STRUCTURAL  the audit refused an exclusion: the member builds on the
#                 excluded target, or its build fails for another reason. A
#                 restriction may not hide a cell that could run, or a red —
#                 delete the `"targets"` line, or file the compiler row that
#                 makes the build refuse it
#   NOT RUNNABLE  the target is one `botopink test` cannot run at all (beam,
#                 wasm): a capability gap of the CLI, met only when such a
#                 target is asked for by name. Nothing ran, and a pair that
#                 did not run is never a pass: it fails the run
#
# The last line is
#   test-libs: <P> passed, <F> failed, <N> without tests, <A> restrictions audited
# with `, <X> restrictions not structural` and `, <S> not runnable by botopink
# test` appended when they are not zero — each of the two fails the run. It is
# preceded by the result store's line (decision 229, the runner's
# `result_store.zig`):
#   result store: <J> jobs — <R> run, <S> from store
# — of the <J> pairs that spawn (cells that test or compile, audits), how many
# ran and how many were answered from a stored pass; a pair answered from the
# store says `(from store)` on its own line. `--cold` (passed to the runner)
# never reads the store, and writes the passes it ran.
#
# Exit codes:
#   0  every cell passed (or has no tests and compiled) and every exclusion
#      is structural
#   1  the runner is not built, a cell failed, an exclusion is not structural,
#      a requested target is one `botopink test` cannot run, or a workspace
#      document quotes the tool's member list and disagrees with it
#   N  the runner's own error exit (bad arguments, no library root)
#
# Pass `--json` to get the runner's raw JSONL instead, and `--list` to get its
# plan (one `<lib>\t<target>\t<kind>` line per pair, nothing spawned): both
# are the runner's output, not a verdict.
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
    case "$a" in
        --json | --list) exec "$runner" "$@" ;;
    esac
done

field() { # field <json-line> <key> — a string value with no escaped quote in it
    sed -n "s/.*\"$2\":\"\([^\"]*\)\".*/\1/p" <<<"$1"
}
# audit_text <json-line> <key> — a string value of a `restriction_audit` (or
# `result_store`) record, which may carry JSON escapes (`\"`, `\\`): everything
# up to the next key.
audit_text() {
    local next
    case "$2" in
        line) next='","at":"' ;;
        at|note) next='"}' ;;
    esac
    printf '%s\n' "$1" | awk -v key="\"$2\":\"" -v next_key="$next" '{
        i = index($0, key); if (!i) exit
        rest = substr($0, i + length(key))
        j = (next_key == "\"}") ? length(rest) - 1 : index(rest, next_key)
        if (j < 1) exit
        v = substr(rest, 1, j - 1)
        gsub(/\\"/, "\"", v); gsub(/\\\\/, "\\", v)
        print v
    }'
}

passed=0; failed=0; not_runnable=0; no_tests=0; audited=0; not_structural=0
store_line=""
doc_quotes_bad=0
runner_exit=0
unexpected=""; refused=""; unran=""

# The runner writes each cell's JSONL on stdout and the child's diagnostics on
# stderr, in order; merged, a cell's diagnostics precede its `cell_summary`
# (and a refused exclusion's precede its `restriction_audit`).
set +e
while IFS= read -r line; do
    case "$line" in
        '{"lib":'*'"event":"test"'*)
            # Only a failed test is printed; the substring test spares a
            # `sed` per passing test (thousands per run).
            case "$line" in *'"status":"fail"'*) ;; *) continue ;; esac
            if [ "$(field "$line" status)" = "fail" ]; then
                printf '  FAIL test %s — %s (%s:%s)\n' "$(field "$line" name)" \
                    "$(field "$line" error_message)" "$(field "$line" error_file)" \
                    "$(sed -n 's/.*"error_line":\([0-9]*\).*/\1/p' <<<"$line")"
            fi
            ;;
        '{"lib":'*) ;; # per-cell test summary — the cell_summary carries the verdict
        '{"event":"lib"'*) ;; # discovery record: the library's directory
        '{"event":"doc_quote_mismatch"'*) doc_quotes_bad=1 ;;
        '{"event":"restriction_audit"'*)
            lib="$(field "$line" lib)"; target="$(field "$line" target)"
            status="$(field "$line" status)"
            found="$(audit_text "$line" line)"; at="$(audit_text "$line" at)"
            from=""; case "$line" in *'"from_store":true'*) from=" (from store)" ;; esac
            case "$status" in
                ok)
                    audited=$((audited + 1))
                    printf '\033[2m── %s · %s: excluded by "targets" — structural: %s%s%s\033[0m\n' \
                        "$lib" "$target" "$found" "${at:+ ($at)}" "$from"
                    ;;
                *)
                    not_structural=$((not_structural + 1)); refused="$refused ${lib}·${target}"
                    printf '\033[1;31m── %s · %s: NOT STRUCTURAL — excluded by "targets", and %s%s\033[0m\n' \
                        "$lib" "$target" "$found" "${at:+ ($at)}"
                    ;;
            esac
            ;;
        '{"event":"cell_summary"'*)
            lib="$(field "$line" lib)"; target="$(field "$line" target)"
            status="$(field "$line" status)"
            from=""; case "$line" in *'"from_store":true'*) from=" (from store)" ;; esac
            case "$status" in
                pass)
                    passed=$((passed + 1))
                    printf '\033[32m── %s · %s: pass%s\033[0m\n' "$lib" "$target" "$from"
                    ;;
                fail)
                    failed=$((failed + 1)); unexpected="$unexpected ${lib}·${target}"
                    printf '\033[1;31m── %s · %s: FAIL\033[0m\n' "$lib" "$target"
                    ;;
                skipped_unsupported)
                    not_runnable=$((not_runnable + 1)); unran="$unran ${lib}·${target}"
                    printf '\033[1;31m── %s · %s: NOT RUNNABLE — `botopink test` cannot run this target; nothing ran\033[0m\n' "$lib" "$target"
                    ;;
                no_tests)
                    no_tests=$((no_tests + 1))
                    printf '── %s · %s: no tests — the library has no test {} block; its .bp sources, if any, compiled%s\n' "$lib" "$target" "$from"
                    ;;
                *)
                    # A status this script does not know is never a pass.
                    failed=$((failed + 1)); unexpected="$unexpected ${lib}·${target}"
                    printf '\033[1;31m── %s · %s: FAIL — unknown cell status `%s`\033[0m\n' "$lib" "$target" "$status"
                    ;;
            esac
            ;;
        '{"event":"result_store"'*)
            store_line="result store: $(sed -n 's/.*"jobs":\([0-9]*\).*/\1/p' <<<"$line") jobs — $(sed -n 's/.*"ran":\([0-9]*\).*/\1/p' <<<"$line") run, $(sed -n 's/.*"from_store":\([0-9]*\).*/\1/p' <<<"$line") from store"
            note="$(audit_text "$line" note)"
            [ -z "$note" ] || store_line="$store_line ($note)"
            ;;
        '{"event":"run_summary"'*) ;;
        __runner_exit=*) runner_exit="${line#__runner_exit=}" ;;
        *) printf '%s\n' "$line" ;;
    esac
done < <("$runner" --json "$@" 2>&1; echo "__runner_exit=$?")
set -e

echo
[ -z "$store_line" ] || printf '%s\n' "$store_line"
printf 'test-libs: %d passed, %d failed, %d without tests, %d restrictions audited' \
    "$passed" "$failed" "$no_tests" "$audited"
[ "$not_structural" -gt 0 ] && printf ', %d restrictions not structural' "$not_structural"
[ "$not_runnable" -gt 0 ] && printf ', %d not runnable by botopink test' "$not_runnable"
printf '\n'

if [ "$failed" -gt 0 ]; then
    echo "test-libs: FAILED cells:$unexpected" >&2
fi
if [ "$not_structural" -gt 0 ]; then
    echo "test-libs: restrictions that are not structural (delete the \"targets\" line, or file the compiler row that makes the build refuse it):$refused" >&2
fi
if [ "$not_runnable" -gt 0 ]; then
    echo "test-libs: pairs \`botopink test\` cannot run — nothing ran there, and that is not a pass:$unran" >&2
fi
if [ "$doc_quotes_bad" -ne 0 ]; then
    echo "test-libs: a workspace document quotes the tool's member list and disagrees with it (named above)" >&2
fi
if [ "$failed" -gt 0 ] || [ "$not_structural" -gt 0 ] || [ "$not_runnable" -gt 0 ] || [ "$doc_quotes_bad" -ne 0 ]; then
    exit 1
fi
# Nothing failed but the runner still exited non-zero (bad arguments, no
# library root, a verdict this script did not read): its exit is the run's.
if [ "$runner_exit" != "0" ]; then
    exit "$runner_exit"
fi
exit 0
