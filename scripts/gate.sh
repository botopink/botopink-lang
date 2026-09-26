#!/usr/bin/env bash
# gate.sh — the botopink-lang gate, one ordered run. Stages 1–4 run one after
# the other, each only after the previous one passed, so a failure there is
# found by the cheapest stage that can see it. Stages 4b–10 only read the tree
# stage 4 has built and tested, so they run SIDE BY SIDE, each with its output
# captured; they are then printed one block per stage in the order below, and
# the gate stops at the first red one IN THAT ORDER — the stage, the output and
# the exit status the one-at-a-time gate printed (§ side by side, below).
#
#   1. staged files: no conflict markers, `zig fmt --check` on staged .zig, no
#                           snapshot candidate (`*.snap.new`, `*.snap.md.new`)
#                           staged (--staged)
#   2. zig build            the CLI, the LSP and the runners link
#   3. format-check.sh      `botopink format --check` over the compiler's own
#                           canonical `.bp` trees (decision 66 — the scan has a
#                           caller); the trees, and the red ones with their
#                           causes, are named in scripts/format-check.sh
#   4. zig build test       compiler-core + language-server + CLI +
#                           lib-test-runner unit suites
#                           (--cold deletes the runtime cache first)
#   4b. snap_audit.sh --mode=runtime-parity  every codegen snapshot recorded
#                           under both comptime runtimes, the pairs equal but
#                           for their listing sections (front 18 step 4)
#   5. zig build test-bpmp  the package manager's unit suite
#   6. beam_export_audit.sh every beam snapshot module assembles with every
#                           function exported (needs erlc)
#   7. zig build test-cli   modules/compiler-cli/tests/*.sh — the command
#                           contract, test tooling, recursion, backend parity
#   8. zig build test-libs  every `.bp` library the checkout can see, per target
#                           (a library without tests is still compiled);
#                           known reds named by scripts/known-red-libs.txt, and
#                           every cell a member's "targets" list excludes run
#                           anyway and pinned by scripts/restricted-targets.txt
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
#             stale cache entry can hide a backend that never ran. Never
#             answered from the green-tree record below.
#   --staged  also run stage 1 over `git diff --cached` (the pre-commit and
#             pre-merge-commit hooks).
#
# One gate at a time per machine (§ gate lock): a second `gate.sh` waits for
# the first, naming its pid, checkout and start time. The stages already use
# every CPU; two gates side by side took far more than twice as long and
# starved each other's timing-sensitive tests.
#
# A `--staged` run whose trees were already gated green (§ green-tree record)
# runs stage 1 and stops: what the commit's diff can affect is nothing that
# gate did not already run on the same bytes.
#
# Exit 0 when every stage passed; 1 at the first stage that failed.
set -euo pipefail

cold=0
staged=0
for a in "$@"; do
    case "$a" in
        --cold) cold=1 ;;
        --staged) staged=1 ;;
        -h|--help) sed -n '2,56p' "$0"; exit 0 ;;
        *) echo "gate: unknown argument '$a'" >&2; exit 1 ;;
    esac
done

root="$(git rev-parse --show-toplevel)"
cd "$root"

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
stage() { printf '\n==> gate: %s\n' "$1"; }
pass() { printf "${GREEN}✓ %s${NC}\n" "$1"; }
fail() { printf "${RED}✗ %s${NC}\n" "$1" >&2; exit 1; }

# ── § gate lock ──────────────────────────────────────────────────────────────
# One gate per machine: every checkout and worktree takes the same lock, a
# directory created with `mkdir` (atomic everywhere, including the macOS
# runner's bash 3.2, which has no `flock`). The holder writes its pid, checkout
# and start time into it and removes it on exit. A second gate waits, printing
# who holds it; a lock whose pid is no longer alive was left by a killed gate
# and is taken over. There is no flag or variable that skips the wait.
lock_dir="${XDG_RUNTIME_DIR:-$HOME/.cache}/botopink/gate.lock"
mkdir -p "$(dirname "$lock_dir")"
cleanup_dirs=()
cleanup() { rm -rf ${cleanup_dirs[@]+"${cleanup_dirs[@]}"}; }
trap cleanup EXIT
waited=0
while ! mkdir "$lock_dir" 2>/dev/null; do
    holder="$(cat "$lock_dir/pid" 2>/dev/null || true)"
    if [ -n "$holder" ] && ! kill -0 "$holder" 2>/dev/null; then
        # The holder is gone without removing its lock — take it over.
        rm -rf "$lock_dir"
        continue
    fi
    if [ "$waited" -eq 0 ]; then
        printf 'gate: another gate holds the lock — pid %s, %s, since %s; waiting for it to finish\n' \
            "${holder:-?}" "$(cat "$lock_dir/checkout" 2>/dev/null || echo '?')" \
            "$(cat "$lock_dir/since" 2>/dev/null || echo '?')" >&2
    fi
    waited=1
    sleep 5
done
cleanup_dirs+=("$lock_dir")
echo "$$" >"$lock_dir/pid"
echo "$root" >"$lock_dir/checkout"
date '+%Y-%m-%d %H:%M:%S' >"$lock_dir/since"
[ "$waited" -eq 0 ] || echo "gate: lock taken" >&2

if [ "$staged" -eq 1 ]; then
    stage "staged files"
    files="$(git diff --cached --name-only --diff-filter=ACMR)"
    lt7=$(printf '<%.0s' {1..7}); eq7=$(printf '=%.0s' {1..7}); gt7=$(printf '>%.0s' {1..7})
    marker_re="^(${lt7} |${eq7}\$|${gt7} )"
    hits=""; bad_fmt=""; candidates=""
    while IFS= read -r f; do
        [ -n "$f" ] || continue
        # A snapshot candidate is written by a mismatch or a missing snapshot
        # and recorded by renaming it; the candidate itself is never committed,
        # `.gitignore` or not (`git add -f` gets past that).
        case "$f" in
            *.snap.new|*.snap.md.new) candidates="$candidates $f" ;;
        esac
        [ -f "$f" ] || continue
        if grep -qE "$marker_re" "$f" 2>/dev/null; then hits="$hits $f"; fi
        case "$f" in
            *.zig) zig fmt --check "$f" >/dev/null 2>&1 || bad_fmt="$bad_fmt $f" ;;
        esac
    done <<<"$files"
    [ -z "$candidates" ] || fail "snapshot candidates staged:$candidates (record one by renaming it without .new; never commit the candidate)"
    [ -z "$hits" ] || fail "conflict markers in:$hits"
    [ -z "$bad_fmt" ] || fail "zig fmt --check failed for:$bad_fmt (run: zig fmt <file>)"
    pass "no conflict markers, staged .zig formatted, no snapshot candidate staged"
fi

# A hook runs with the committing repository's GIT_DIR, GIT_INDEX_FILE, … in
# the environment. Stage 1 needed them; nothing after it may inherit them: a
# test that runs `git` in a scratch repository (bpmp's install tests) would
# otherwise commit into, and check out branches of, this repository.
# shellcheck disable=SC2046
unset $(git rev-parse --local-env-vars)

# ── § green-tree record ──────────────────────────────────────────────────────
# What a gate reads: this checkout's working tree and every sibling library
# checkout `test-libs` reaches (`<checkout root>/repository/*`), under one
# toolchain. `tree_key` hashes exactly that — each repository's working tree as
# `git write-tree` would record it with every change added (a scratch index,
# seeded from the real one so unchanged files are not re-read), plus the
# versions of zig, OTP and node. A gate that passes records the key it started
# from, and only if the key is the same when it ends (nothing moved under it).
# A `--staged` run — a commit or a merge — whose key was already recorded
# green has nothing left that its diff can affect, and stops after stage 1; any
# other difference, however small, runs the whole gate. A `--cold` run never
# reads the record.
tree_key() {
    local top repos r idx
    top="$root"
    while [ "$top" != "/" ] && [ ! -d "$top/repository" ]; do top="$(dirname "$top")"; done
    repos="$root"
    if [ -d "$top/repository" ]; then
        for r in "$top"/repository/*/; do
            r="${r%/}"
            [ "$r" = "$root" ] && continue
            git -C "$r" rev-parse --git-dir >/dev/null 2>&1 && repos="$repos
$r"
        done
    fi
    idx="$(mktemp "${TMPDIR:-/tmp}/bp-gate-index.XXXXXX")"
    {
        while IFS= read -r r; do
            cp "$(git -C "$r" rev-parse --path-format=absolute --git-path index)" "$idx" 2>/dev/null || rm -f "$idx"
            printf '%s ' "$r"
            GIT_INDEX_FILE="$idx" git -C "$r" add -A . >/dev/null 2>&1
            GIT_INDEX_FILE="$idx" git -C "$r" write-tree
        done <<<"$repos"
        zig version
        erl -noshell -eval 'io:format("~s~n", [erlang:system_info(otp_release)]), halt().' 2>/dev/null || echo no-erl
        node --version 2>/dev/null || echo no-node
    } | git hash-object --stdin
    rm -f "$idx"
}
green_record="$(git rev-parse --path-format=absolute --git-path botopink-gate-green)"
start_key="$(tree_key)"
if [ "$staged" -eq 1 ] && [ "$cold" -eq 0 ] && [ -f "$green_record" ] &&
    [ "$(cat "$green_record")" = "$start_key" ]; then
    stage "stages 2–10"
    pass "this checkout and its libraries are the trees a gate already passed on (key ${start_key:0:12}) — nothing the diff can affect is left to run"
    printf "\n${GREEN}gate: every stage passed${NC}\n"
    exit 0
fi

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

# ── § side by side: stages 4b–10 ─────────────────────────────────────────────
# Each reads what stages 2–4 left and writes only its own scratch (`mktemp`
# directories, per-run `test-out/<target>/<id>/`, per-process test-scratch
# roots); `test-cli`'s four scripts, which share `zig-out/` and fixture `out/`
# directories, stay one stage and run in order inside it. The pools inside
# `test-libs`, `test-language` and `test-docs` admit a job only while the
# machine's runnable threads are at most its CPUs, so running them together
# shares the CPUs rather than multiplying the load.
#
# Every stage runs to completion even when an earlier one is red — that is the
# price of a red run, never of a green one. The report is the serial gate's: the
# blocks are printed in stage order up to and including the first red stage,
# whose failure line ends the run with exit 1; the stages after it are not
# printed, as the serial gate never ran them. A stage's stdout and stderr share
# one capture file, so both reach this script's stdout in the order written.
par="$(mktemp -d "${TMPDIR:-/tmp}/bp-gate.XXXXXX")"
cleanup_dirs+=("$par")
launch() { # <n> <cmd…> — run in the background, output in $par/<n>.out, status in $par/<n>.rc
    local n="$1"
    shift
    (
        if "$@" >"$par/$n.out" 2>&1; then echo 0 >"$par/$n.rc"; else echo $? >"$par/$n.rc"; fi
    ) &
}
launch 1 bash scripts/snap_audit.sh --mode=runtime-parity
launch 2 zig build test-bpmp
launch 3 bash scripts/beam_export_audit.sh
launch 4 zig build test-cli
launch 5 zig build test-libs
launch 6 zig build test-language
launch 7 zig build test-docs
wait

report() { # <n> <stage title> <pass text> <fail text>
    stage "$2"
    cat "$par/$1.out"
    [ "$(cat "$par/$1.rc" 2>/dev/null)" = 0 ] || fail "$4"
    pass "$3"
}
report 1 "comptime runtime parity (snap_audit.sh --mode=runtime-parity)" "comptime runtime parity" \
    "scripts/snap_audit.sh --mode=runtime-parity (the diff above names the pair; a difference is a defect in one runtime, never re-recorded away)"
report 2 "zig build test-bpmp" "zig build test-bpmp" "zig build test-bpmp"
report 3 "beam export audit" "beam export audit" \
    "scripts/beam_export_audit.sh (a REJECTED block above names the module, function and reason)"
report 4 "zig build test-cli" "zig build test-cli" "zig build test-cli"
report 5 "zig build test-libs" "zig build test-libs" "zig build test-libs"
report 6 "zig build test-language" "zig build test-language" \
    "zig build test-language (a FAIL line above names the file, the test and the rule)"
report 7 "zig build test-docs" "zig build test-docs" \
    "zig build test-docs (a ✗ line above names the doc, the fence line and the error)"

# Record the trees as green — only when nothing moved while the gate ran.
if [ "$(tree_key)" = "$start_key" ]; then
    echo "$start_key" >"$green_record"
fi

printf "\n${GREEN}gate: every stage passed${NC}\n"
