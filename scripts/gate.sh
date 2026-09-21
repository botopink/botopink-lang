#!/usr/bin/env bash
# gate.sh — the botopink-lang gate, one ordered run. Each stage runs only after
# the previous one passed, so a failure is found by the cheapest stage that can
# see it.
#
#   1. staged files: no conflict markers, `zig fmt --check` on staged .zig (--staged)
#   2. zig build            the CLI, the LSP and the runners link
#   3. format-check.sh      `botopink format --check` over the compiler's own
#                           canonical `.bp` trees (decision 66 — the scan has a
#                           caller); the trees, and the red ones with their
#                           causes, are named in scripts/format-check.sh
#   4. zig build test       compiler-core + language-server + CLI +
#                           lib-test-runner unit suites
#                           (--cold deletes the runtime cache first)
#   5. zig build test-bpmp  the package manager's unit suite
#   6. beam_export_audit.sh every beam snapshot module assembles with every
#                           function exported (needs erlc)
#   7. zig build test-cli   modules/compiler-cli/tests/*.sh — the command
#                           contract, test tooling, recursion, backend parity
#   8. zig build test-libs  every `.bp` library the checkout can see, per target
#                           (a library without tests is still compiled);
#                           known reds named by scripts/known-red-libs.txt
#   9. zig build test-language  tests/language — decision 8's `case`, tuples and
#                           `loop` in botopink, on commonJS and erlang; expected
#                           failures named by tests/language/expected-failures.txt
#  10. zig build test-docs  every `botopink` fence of docs.md and README.md is
#                           compiled (scripts/check-docs.sh)
#
# Usage:
#   scripts/gate.sh [--cold] [--staged]
#
#   --cold    delete modules/compiler-core/.botopinkbuild/runtime-cache before
#             `zig build test`. Required for the run that decides a merge: a
#             stale cache entry can hide a backend that never ran.
#   --staged  also run stage 1 over `git diff --cached` (the pre-commit hook).
#
# Exit 0 when every stage passed; 1 at the first stage that failed.
set -euo pipefail

cold=0
staged=0
for a in "$@"; do
    case "$a" in
        --cold) cold=1 ;;
        --staged) staged=1 ;;
        -h|--help) sed -n '2,32p' "$0"; exit 0 ;;
        *) echo "gate: unknown argument '$a'" >&2; exit 1 ;;
    esac
done

root="$(git rev-parse --show-toplevel)"
cd "$root"

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
stage() { printf '\n==> gate: %s\n' "$1"; }
pass() { printf "${GREEN}✓ %s${NC}\n" "$1"; }
fail() { printf "${RED}✗ %s${NC}\n" "$1" >&2; exit 1; }

if [ "$staged" -eq 1 ]; then
    stage "staged files"
    files="$(git diff --cached --name-only --diff-filter=ACM)"
    lt7=$(printf '<%.0s' {1..7}); eq7=$(printf '=%.0s' {1..7}); gt7=$(printf '>%.0s' {1..7})
    marker_re="^(${lt7} |${eq7}\$|${gt7} )"
    hits=""; bad_fmt=""
    while IFS= read -r f; do
        [ -n "$f" ] && [ -f "$f" ] || continue
        if grep -qE "$marker_re" "$f" 2>/dev/null; then hits="$hits $f"; fi
        case "$f" in
            *.zig) zig fmt --check "$f" >/dev/null 2>&1 || bad_fmt="$bad_fmt $f" ;;
        esac
    done <<<"$files"
    [ -z "$hits" ] || fail "conflict markers in:$hits"
    [ -z "$bad_fmt" ] || fail "zig fmt --check failed for:$bad_fmt (run: zig fmt <file>)"
    pass "no conflict markers, staged .zig formatted"
fi

# A hook runs with the committing repository's GIT_DIR, GIT_INDEX_FILE, … in
# the environment. Stage 1 needed them; nothing after it may inherit them: a
# test that runs `git` in a scratch repository (bpmp's install tests) would
# otherwise commit into, and check out branches of, this repository.
# shellcheck disable=SC2046
unset $(git rev-parse --local-env-vars)

stage "zig build"
zig build || fail "zig build"
pass "zig build"

stage "botopink format --check (scripts/format-check.sh)"
bash scripts/format-check.sh || fail "scripts/format-check.sh (the tree and its files are named above; the script's header names the trees that are red today and why)"
pass "botopink format --check"

stage "zig build test$([ "$cold" -eq 1 ] && echo ' (cold runtime cache)')"
if [ "$cold" -eq 1 ]; then
    rm -rf modules/compiler-core/.botopinkbuild/runtime-cache
fi
zig build test || fail "zig build test"
pass "zig build test"

stage "zig build test-bpmp"
zig build test-bpmp || fail "zig build test-bpmp"
pass "zig build test-bpmp"

stage "beam export audit"
bash scripts/beam_export_audit.sh || fail "scripts/beam_export_audit.sh (a REJECTED block above names the module, function and reason)"
pass "beam export audit"

stage "zig build test-cli"
zig build test-cli || fail "zig build test-cli"
pass "zig build test-cli"

stage "zig build test-libs"
zig build test-libs || fail "zig build test-libs"
pass "zig build test-libs"

stage "zig build test-language"
zig build test-language || fail "zig build test-language (a FAIL line above names the file, the test and the rule)"
pass "zig build test-language"

stage "zig build test-docs"
zig build test-docs || fail "zig build test-docs (a ✗ line above names the doc, the fence line and the error)"
pass "zig build test-docs"

printf "\n${GREEN}gate: every stage passed${NC}\n"
