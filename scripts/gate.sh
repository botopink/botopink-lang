#!/usr/bin/env bash
# gate.sh — the botopink-lang gate, one ordered run. Stages 1–4 run one after
# the other, each only after the previous one passed, so a failure there is
# found by the cheapest stage that can see it. Stages 4b–12 only read the tree
# stage 4 has built and tested, so they run SIDE BY SIDE, each with its output
# captured; they are then printed one block per stage in the order below, and
# the gate stops at the first red one IN THAT ORDER — the stage, the output and
# the exit status the one-at-a-time gate printed (§ side by side, below).
#
#   1. staged files: no conflict markers, `zig fmt --check` on staged .zig, no
#                           snapshot candidate (`*.snap.new`, `*.snap.md.new`)
#                           staged (--staged); then, every run, `zig fmt --check
#                           modules` — a `.zig` file red anywhere fails the
#                           gate, staged or not; then the `erl` on PATH is the
#                           OTP release the compiler emits for (decision 228,
#                           § the OTP release), or the gate stops before stage 2
#   2. zig build           the CLI, the LSP and the runners link, built
#                           -Doptimize=ReleaseSafe — the shipped mode, and the
#                           binaries every later stage runs (§ build mode)
#   3. format-check.sh      `botopink format --check` over the compiler's own
#                           `.bp` trees (decision 66 — the scan has a caller);
#                           the trees, every one canonical, are named in
#                           scripts/format-check.sh
#   3b. backend partition   codegen/backend-partition.txt audited
#                           (scripts/lib/backend-partition-audit.js, decision 249)
#   4. zig build test       compiler-core + language-server + CLI +
#                           lib-test-runner unit suites
#                           (--cold deletes the runtime cache and every
#                           `.botopinkbuild/cache/` first)
#   5. zig build test-bpmp  the package manager's unit suite
#   6. beam_export_audit.sh every beam snapshot module assembles with every
#                           function exported (needs erlc)
#   7. zig build test-cli   modules/compiler-cli/tests/*.sh — the command
#                           contract, test tooling, wasm --invoke main
#   8. zig build test-libs  every `.bp` library the checkout can see, per target
#                           (a library without tests is still compiled); the
#                           manifests decide the cells — one that exists is
#                           green or the stage fails — and every target a
#                           member's "targets" list excludes is audited
#   9. zig build test-conformance  conformance/ — the conformance suite
#                           (decisions 457, 464, 466): every cell of
#                           conformance/modules/ by `botopink cell check` on
#                           every target it declares, every conformance/test/
#                           suite by `botopink test --json`; a red cell fails
#                           the stage
#  10. zig build test-docs  every `<!-- example: … -->` of the language reference
#                           (conformance/docs.md, each cell's docs.md, README.md)
#                           names a conformance cell or suite, and no
#                           ```botopink fence is left inline
#                           (scripts/check-docs.sh; decision 461)
#  11. tsc-check.sh         every `.d.ts` the commonJS backend emits for the
#                           conformance cells and every package under libs/
#                           (std included) passes
#                           `tsc --noEmit --strict`, and every emitted `.js`
#                           passes `node --check` (needs `npx` and `node`)
#  12. zig build test-web   compiler-core built for wasm32-wasi (the browser
#                           compiler) and modules/compiler-web/tests/smoke.js
#                           under node — CI's step, so its red is the gate's
#                           (decision 231); default build mode, as CI runs it
#
# Usage:
#   scripts/gate.sh [--cold] [--staged] [--no-conformance]
#
# Two modes, decided by the current branch alone (§ step gate and full gate;
# decision 460) — there is no flag or variable for it. On a `front/*` branch the
# STEP gate runs every stage but narrows stages 8 and 9 to the cells the step's
# change reaches (the backend partition, decision 249); on `feat`, `main`, a
# detached HEAD or any other branch the FULL gate runs every cell. The first
# line the gate prints names the mode and why.
#
#   --cold    delete modules/compiler-core/.botopinkbuild/runtime-cache before
#             `zig build test`, and every `.botopinkbuild/cache/` (decision 225:
#             the code cache of the dependencies' modules, the cell durations)
#             under this checkout and each sibling library repository, naming
#             each, and pass `--cold` to stages 8 and 9 (the code cache is not read
#             there). Every test and every cell runs on every run (decision 510);
#             `--cold` only drops the caches the compiler builds from.
#             Required for the run that decides a merge: a stale cache entry can
#             hide a backend that never ran. Never answered from the green-tree
#             record below.
#   --staged  also run stage 1 over `git diff --cached` (the pre-commit and
#             pre-merge-commit hooks).
#
#   --no-conformance
#             skip the conformance stage — stage 9, `test-conformance` —
#             and print `gate: conformance not run (--no-conformance)`; every
#             other stage runs as without the flag. The commit hook runs it
#             (decision 470); a front's Conformance step and its landing run the
#             gate WITH conformance. Such a run never writes the green-tree
#             record and is never a full gate.
#
# One gate with conformance at a time per machine (§ gate lock): a second one
# waits for the first, naming its pid, checkout and start time. A
# `--no-conformance` run (the commit hook's) takes no lock and never waits
# (decision 508).
#
# A `--staged` run whose trees were already gated green (§ green-tree record)
# runs stage 1 and stops: what the commit's diff can affect is nothing that
# gate did not already run on the same bytes.
#
# Every stage's line ends with its wall clock and CPU-seconds, stages 8–10 are
# held to the plan their runners' `--list` prints (§ counts), and the last line
# is the run's total against the budget (§ budget).
#
# Exit 0 when every stage passed; 1 at the first stage that failed.
set -euo pipefail

cold=0
staged=0
no_conformance=0
for a in "$@"; do
    case "$a" in
        --cold) cold=1 ;;
        --staged) staged=1 ;;
        --no-conformance) no_conformance=1 ;;
        -h|--help) sed -n '2,78p' "$0"; exit 0 ;;
        *) echo "gate: unknown argument '$a'" >&2; exit 1 ;;
    esac
done

# The wall-clock budget of a run on the reference machine (16 idle cores), in
# seconds — § budget at the end. Decision 265 sets 7m30s for this milestone —
# the 5-minute target is deferred to the next milestone.
budget=450

root="$(git rev-parse --show-toplevel)"
cd "$root"

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
stage() { printf '\n==> gate: %s\n' "$1"; }
# § stage times — every stage is timed with bash's `time` keyword (bash 3.2
# has it): wall clock and the CPU-seconds of the stage and every child it
# waited for. `timed <file> <cmd…>` runs the command with its own stdout and
# stderr untouched and writes `<wall> <user> <sys>` to <file>.
timed() {
    local tf="$1" TIMEFORMAT='%R %U %S'
    shift
    { time "$@" 2>&3 3>&-; } 3>&2 2>"$tf"
}
# fmt_time <seconds> — `4m12s`, `41.3s`
fmt_time() { awk -v s="$1" 'BEGIN { if (s >= 60) printf "%dm%02ds", int(s / 60), int(s % 60); else printf "%.1fs", s }'; }
# stage_time <file> — `41.3s wall, 210 CPU-s`. The locale may print the
# times with a decimal comma; awk reads a point.
stage_time() {
    tr ',' '.' <"$1" | awk '{ s = $1; c = $2 + $3
        if (s >= 60) printf "%dm%02ds", int(s / 60), int(s % 60); else printf "%.1fs", s
        printf " wall, %.0f CPU-s", c }'
}
pass() { printf "${GREEN}✓ %s${NC}\n" "$1"; }
fail() { printf "${RED}✗ %s${NC}\n" "$1" >&2; exit 1; }

# ── § gate lock ──────────────────────────────────────────────────────────────
# One gate with conformance per machine: every checkout and worktree takes the
# same lock, a directory created with `mkdir` (atomic everywhere, including the
# macOS runner's bash 3.2, which has no `flock`). The holder writes its pid,
# checkout and start time into it and removes it on exit. A second gate waits,
# printing who holds it; a lock whose pid is no longer alive was left by a
# killed gate and is taken over. A `--no-conformance` run takes no lock and
# never waits (decision 508): the commit hooks of parallel tasks run side by
# side. There is no flag or variable that skips the wait of a conformance run.
lock_dir="${XDG_RUNTIME_DIR:-$HOME/.cache}/botopink/gate.lock"
mkdir -p "$(dirname "$lock_dir")"
cleanup_dirs=()
# A stage started ahead of its report (stage 4, § stage 4 beside 2 and 3) is
# waited for before its scratch goes: a red stage 2 does not leave it running.
early_pids=()
cleanup() {
    local p
    for p in ${early_pids[@]+"${early_pids[@]}"}; do wait "$p" 2>/dev/null || true; done
    rm -rf ${cleanup_dirs[@]+"${cleanup_dirs[@]}"}
}
trap cleanup EXIT
waited=0
while [ "$no_conformance" -eq 0 ] && ! mkdir "$lock_dir" 2>/dev/null; do
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
if [ "$no_conformance" -eq 0 ]; then
    cleanup_dirs+=("$lock_dir")
    echo "$$" >"$lock_dir/pid"
    echo "$root" >"$lock_dir/checkout"
    date '+%Y-%m-%d %H:%M:%S' >"$lock_dir/since"
    [ "$waited" -eq 0 ] || echo "gate: lock taken" >&2
fi
gate_start="$(date +%s)"
# One scratch directory per run: the stage times, and each side-by-side stage's
# capture and exit status (§ side by side).
par="$(mktemp -d "${TMPDIR:-/tmp}/bp-gate.XXXXXX")"
cleanup_dirs+=("$par")
tdir="$par"

# ── § step gate and full gate ────────────────────────────────────────────────
# Decision 460: the branch decides the mode, structurally — a flag, a variable
# or a file a commit sets cannot (decision 67). On a `front/*` branch the gate is
# the STEP gate: every stage runs, and the cells of stages 8 (test-libs) and 9
# (test-conformance) are the ones the step's change reaches, by the backend
# partition of decision 249 (scripts/lib/gate-mode.sh). On `feat`, `main`, a
# detached HEAD or any other branch it is the FULL gate: every stage, every cell,
# every library. The step's change is the working tree against the merge-base
# with `origin/feat` (committed, staged, unstaged and untracked files), so a step
# gate covers the whole step, not the last commit. A front's Conformance step and
# its landing run the full gate on the main checkout at a detached HEAD
# (scripts/AGENTS.md § Step gate and full gate). One line says which mode and why.
# shellcheck source=lib/gate-mode.sh
. scripts/lib/gate-mode.sh
gate_branch="$(git symbolic-ref --short -q HEAD || true)"
gate_kind="$(gate_mode "$gate_branch")"
lang_args=()   # test-conformance's target subset (empty: every target)
libs_args=()   # test-libs' target subset (empty: its default targets)
run_lang=1
run_libs=1
if [ "$gate_kind" = step ]; then
    if gate_base="$(git merge-base HEAD refs/remotes/origin/feat 2>/dev/null)"; then
        gate_changed="$({ git diff --no-renames --name-only "$gate_base"; git ls-files --others --exclude-standard; } | sort -u)"
        # shellcheck disable=SC2046
        gate_reach modules/compiler-core/src/codegen/backend-partition.txt $(printf '%s\n' "$gate_changed" | tr '\n' ' ')
    else
        reach_all=1
        reach_targets=""
        reach_why="no origin/feat to measure the step against"
    fi
    if [ "$reach_all" -eq 1 ]; then
        printf 'gate: step gate (branch %s): reaches every backend (%s)\n' "$gate_branch" "$reach_why"
    else
        lib_targets=""
        for t in ${reach_targets//,/ }; do
            case "$t" in commonJS|erlang) lib_targets="${lib_targets:+$lib_targets,}$t" ;; esac
        done
        if [ -n "$reach_targets" ]; then lang_args=(--target "$reach_targets"); else run_lang=0; fi
        if [ -n "$lib_targets" ]; then libs_args=(--target "$lib_targets"); else run_libs=0; fi
        printf 'gate: step gate (branch %s): %s; test-conformance %s, test-libs %s\n' "$gate_branch" "$reach_why" \
            "$([ "$no_conformance" -eq 1 ] && echo 'not run (--no-conformance)' || { [ "$run_lang" -eq 1 ] && echo "on $reach_targets" || echo 'skipped, no cell reached'; })" \
            "$([ "$run_libs" -eq 1 ] && echo "on $lib_targets" || echo 'skipped, no library cell reached')"
    fi
else
    if [ -n "$gate_branch" ]; then gate_where="branch $gate_branch"; else gate_where="detached HEAD"; fi
    printf 'gate: full gate (%s): every stage, every cell, every library\n' "$gate_where"
fi

# Decision 470: the conformance cells (test-conformance) are what a front's
# Conformance step runs; the commit hook runs the gate without them.
if [ "$no_conformance" -eq 1 ]; then
    run_lang=0
    echo "gate: conformance not run (--no-conformance)"
fi

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

# The staged check above is the fast path of a commit; the tree is the gate's
# subject. `zig fmt --check` lists every unformatted file under `modules` and
# exits 1 — a file nobody staged is a red the next commit that touches it meets,
# so it is red now (front 112 of 1.0.11-beta; the fmt of the whole tree is its
# step 1).
stage "zig fmt --check modules"
unformatted="$(zig fmt --check modules 2>&1)" || fail "zig fmt --check modules:
$unformatted
(run: zig fmt modules)"
pass "zig fmt --check modules"

# ── § the OTP release ────────────────────────────────────────────────────────
# Decision 228: the compiler emits Erlang for one release, the `OTP_RELEASE`
# constant of modules/manifest/src/root.zig (`botopink --version` prints it),
# and every erlang and beam run refuses another `erl` on PATH. The gate reads
# the constant from that source — the binary is not built yet — and stops here,
# with the compiler's message, before stage 2 builds anything.
stage "Erlang/OTP release"
otp_want="$(sed -n 's/^pub const OTP_RELEASE = "\([0-9][0-9]*\)";$/\1/p' modules/manifest/src/root.zig)"
[ -n "$otp_want" ] || fail "modules/manifest/src/root.zig declares no OTP_RELEASE"
otp_have="$(erl -noshell -eval 'io:format("~s",[erlang:system_info(otp_release)]),halt().' 2>/dev/null)" || otp_have=""
[ -n "$otp_have" ] || fail "botopink emits Erlang for OTP $otp_want, and \`erl\` on PATH did not name its release — install OTP $otp_want and put it on PATH"
[ "$otp_have" = "$otp_want" ] || fail "botopink emits Erlang for OTP $otp_want, and \`erl\` on PATH is OTP $otp_have — install OTP $otp_want and put it on PATH"
pass "Erlang/OTP $otp_have, the release botopink emits for"

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
    stage "stages 2–11"
    pass "this checkout and its libraries are the trees a gate already passed on (key ${start_key:0:12}) — nothing the diff can affect is left to run"
    printf "\n${GREEN}gate: every stage passed${NC}\n"
    exit 0
fi

# ── § build mode ─────────────────────────────────────────────────────────────
# The binaries stages 3 and 4b–10 run are built `-Doptimize=ReleaseSafe` — the
# mode `release.yml` ships — so the gate runs the compiler a user installs.
# ReleaseSafe keeps every runtime safety check (bounds, overflow, `unreachable`,
# `std.debug.assert`); what it drops is Debug's allocator, whose leak report
# never changed an exit status. A Debug `botopink` spends ~12× the CPU of the
# ReleaseSafe one on the same cell, byte for byte the same output (an `emilia-*`
# erlang cell: 189 CPU-s against 15), and stages 8 and 9 are thousands of such
# compiles — rakun's build tests alone spawn the compiler 22 times in one cell.
# Every `zig build` below passes the same `$opt`, so no stage reinstalls a
# Debug binary over the one the others run. Stage 4 builds its own unit-test
# binaries in Debug, as before: `zig build test` installs nothing.
opt=-Doptimize=ReleaseSafe

# ── § ahead of the build: stages 4, 4b, 5 and 6 ──────────────────────────────
# Four stages read nothing stages 2 and 3 produce: `zig build test` and `zig
# build test-bpmp` build and run their own Debug unit-test binaries (no unit
# test spawns `zig-out/bin/*`), and the two audits read snapshots with `erlc`.
# They start now, beside the ReleaseSafe build — whose long pole is one LLVM
# thread per executable — each captured like a side-by-side stage (§ side by
# side) and reported in its place: stage 4 after stage 3, the others after it.
# A red stage 2 or 3 still ends the run first, and the cleanup waits for them;
# their work is then the price of a red run, never of a green one.
launch() { # <n> <cmd…> — run in the background, output in $par/<n>.out, status in $par/<n>.rc
    local n="$1"
    shift
    (
        if timed "$par/$n.time" "$@" >"$par/$n.out" 2>&1; then echo 0 >"$par/$n.rc"; else echo $? >"$par/$n.rc"; fi
    ) &
    early_pids+=("$!")
}
if [ "$cold" -eq 1 ]; then
    rm -rf modules/compiler-core/.botopinkbuild/runtime-cache
    # Every build cache lives under a `.botopinkbuild/cache/` (decision 225):
    # the one of each cache root this gate reads — this checkout and each
    # sibling library repository `test-libs` reaches — goes, so no stage
    # answers an erlang verdict, a `.beam` or a cell's start order from a
    # previous run. Each deleted directory is named.
    cold_top="$root"
    while [ "$cold_top" != "/" ] && [ ! -d "$cold_top/repository" ]; do cold_top="$(dirname "$cold_top")"; done
    cold_repos=("$root")
    if [ -d "$cold_top/repository" ]; then
        for r in "$cold_top"/repository/*/; do
            r="${r%/}"
            [ "$r" = "$root" ] || cold_repos+=("$r")
        done
    fi
    for r in "${cold_repos[@]}"; do
        while IFS= read -r c; do
            [ -n "$c" ] || continue
            rm -rf "$c" || fail "--cold: could not delete $c"
            echo "gate: --cold deleted $c"
        done < <(find "$r" \( -name .git -o -name node_modules -o -name .zig-cache \) -prune -o -type d -path '*/.botopinkbuild/cache' -prune -print)
    done
fi
launch 0 zig build test
test_pid=$!
launch 2 zig build test-bpmp "$opt"
launch 3 bash scripts/beam_export_audit.sh

stage "zig build ($opt)"
timed "$tdir/build.time" zig build "$opt" || fail "zig build $opt"
pass "zig build — $(stage_time "$tdir/build.time")"

stage "botopink format --check (scripts/format-check.sh)"
timed "$tdir/format.time" bash scripts/format-check.sh || fail "scripts/format-check.sh (the tree and its files are named above; run: zig-out/bin/botopink format <tree>, in a reformat-only commit)"
pass "botopink format --check — $(stage_time "$tdir/format.time")"

stage "backend partition audit (scripts/lib/backend-partition-audit.js)"
node scripts/lib/backend-partition-audit.js || fail "scripts/lib/backend-partition-audit.js (the list modules/compiler-core/src/codegen/backend-partition.txt is wrong where it names)"

stage "zig build test$([ "$cold" -eq 1 ] && echo ' (cold runtime cache)')"
wait "$test_pid" || true
cat "$par/0.out"
[ "$(cat "$par/0.rc" 2>/dev/null)" = 0 ] || fail "zig build test"
pass "zig build test — $(stage_time "$par/0.time")"

# ── § the plan of stages 8–10 ────────────────────────────────────────────────
# What stages 8, 9 and 10 must run, read from their own runners before they
# start: `--list` prints the plan and spawns nothing. After each stage, the
# count it printed is held to its plan (§ counts), so a stage cannot be
# narrowed to win time — a run that did fewer cells than the manifests and the
# trees declare fails the gate, green or not.
if [ "$run_libs" -eq 1 ]; then
    bash scripts/test-libs.sh --list ${libs_args[@]+"${libs_args[@]}"} >"$par/plan.libs" 2>"$par/plan.libs.err" ||
        { cat "$par/plan.libs.err"; fail "scripts/test-libs.sh --list"; }
fi
if [ "$run_lang" -eq 1 ]; then
    bash conformance/run.sh --list ${lang_args[@]+"${lang_args[@]}"} >"$par/plan.conformance" 2>"$par/plan.conformance.err" ||
        { cat "$par/plan.conformance.err"; fail "conformance/run.sh --list"; }
fi
bash scripts/check-docs.sh --list >"$par/plan.docs" 2>"$par/plan.docs.err" ||
    { cat "$par/plan.docs.err"; fail "scripts/check-docs.sh --list"; }

# ── § side by side: stages 4b–12 ─────────────────────────────────────────────
# 4b, 5 and 6 are already running (§ ahead of the build); 7–12 start here.
# Each reads what stages 2–4 left and writes only its own scratch (`mktemp`
# directories, per-run `test-out/<target>/<id>/`, per-process test-scratch
# roots); `test-cli`'s four scripts, which share `zig-out/` and fixture `out/`
# directories, stay one stage and run in order inside it. The pools inside
# `test-libs` and `test-conformance` admit a job only while the
# machine's runnable threads are at most its CPUs, so running them together
# shares the CPUs rather than multiplying the load.
#
# Every stage runs to completion even when an earlier one is red — that is the
# price of a red run, never of a green one. The report is the serial gate's: the
# blocks are printed in stage order up to and including the first red stage,
# whose failure line ends the run with exit 1; the stages after it are not
# printed, as the serial gate never ran them. A stage's stdout and stderr share
# one capture file, so both reach this script's stdout in the order written.
# ── § job budget ─────────────────────────────────────────────────────────────
# One budget for the whole side-by-side set, not a pool each: three pools sized
# to the whole machine put ~16 jobs apiece on 16 CPUs (load 4.7 → 26 in a cold
# gate), and the admission each pool does on `procs_running` cannot see a job
# another pool is about to start. The total is `pool_default_jobs` — one per
# CPU, bounded by `MemAvailable / 768 MiB`, read now that the build is done —
# and each stage that runs a pool gets its share of it, in proportion to the
# CPU-seconds it measured (test-libs 2540, test-conformance 1468, the rest under
# 300): 50 % / 30 % / 10 %, at least 1 each; test-docs reads files and runs no
# pool. The stages keep their own
# `--jobs` flag and admission; only the number they are given changes, so a
# report is the bytes it was. test-cli runs its scripts one after another and
# test-web is one wasm compile, so zig gets `-j` of its share.
# shellcheck source=lib/pool.sh
. scripts/lib/pool.sh
budget_total="$(pool_default_jobs)"
share() { # <percent> — that part of the total, at least 1
    local n=$(( budget_total * $1 / 100 ))
    [ "$n" -ge 1 ] || n=1
    echo "$n"
}
echo "gate: job budget $budget_total — test-libs $(share 50), test-conformance $(share 30), tsc-check $(share 10)"
launch 4 zig build test-cli "$opt"
# A stage the step gate skips because the step reaches none of its cells is not
# launched; its report line says so (§ step gate and full gate).
if [ "$run_libs" -eq 1 ]; then
    launch 5 zig build test-libs "$opt" -- --jobs "$(share 50)" ${libs_args[@]+"${libs_args[@]}"}
fi
if [ "$run_lang" -eq 1 ]; then
    launch 6 zig build test-conformance "$opt" -- --jobs "$(share 30)" ${lang_args[@]+"${lang_args[@]}"}
fi
launch 7 zig build test-docs "$opt"
launch 8 bash scripts/tsc-check.sh --jobs "$(share 10)"
launch 9 zig build test-web -j"$(share 10)"
wait

# ── § counts ─────────────────────────────────────────────────────────────────
# `counted <n> <stage> <ran> <planned>` — the stage's own tally against its
# `--list` plan; a difference fails the gate naming both numbers.
plain() { sed -E "s/$(printf '\033')\[[0-9;]*m//g" "$1"; }
counted() {
    [ "$3" = "$4" ] || fail "$2 ran $3, and its plan (--list) declares $4 — a stage may not run fewer than its plan"
}
check_counts() { # <n>
    local out="$par/$1.out" line p f n a x
    case "$1" in
        5)  # test-libs: P + F + N cells, A + X audits (scripts/test-libs.sh)
            line="$(plain "$out" | grep -E '^test-libs: [0-9]+ passed' | tail -1)"
            p="$(sed -nE 's/^test-libs: ([0-9]+) passed.*/\1/p' <<<"$line")"
            f="$(sed -nE 's/.* ([0-9]+) failed.*/\1/p' <<<"$line")"
            n="$(sed -nE 's/.* ([0-9]+) without tests.*/\1/p' <<<"$line")"
            a="$(sed -nE 's/.* ([0-9]+) restrictions audited.*/\1/p' <<<"$line")"
            x="$(sed -nE 's/.* ([0-9]+) restrictions not structural.*/\1/p' <<<"$line")"
            counted 5 "stage 8 (test-libs) cells" "$(( ${p:-0} + ${f:-0} + ${n:-0} ))" "$(cut -f3 "$par/plan.libs" | grep -c '^cell:')"
            counted 5 "stage 8 (test-libs) restriction audits" "$(( ${a:-0} + ${x:-0} ))" "$(cut -f3 "$par/plan.libs" | grep -cx 'audit')"
            echo "plan: $(( ${p:-0} + ${f:-0} + ${n:-0} )) cells and $(( ${a:-0} + ${x:-0} )) audits, as --list declares"
            ;;
        6)  # test-conformance: `cells: <J> jobs — <R> run, <A> audits` (conformance/run.sh)
            line="$(plain "$out" | grep -E '^cells: [0-9]+ jobs' | tail -1)"
            counted 6 "stage 9 (test-conformance) jobs" "$(sed -nE 's/^cells: ([0-9]+) jobs.*/\1/p' <<<"$line")" "$(grep -c . "$par/plan.conformance")"
            counted 6 "stage 9 (test-conformance) audits" "$(sed -nE 's/.* ([0-9]+) audits$/\1/p' <<<"$line")" "$(cut -f3 "$par/plan.conformance" | grep -cx 'audit')"
            echo "plan: $(grep -c . "$par/plan.conformance") jobs on $(cut -f2 "$par/plan.conformance" | sort -u | tr '\n' ' ')as --list declares"
            ;;
        7)  # test-docs: `docs: <N> references — …` (scripts/check-docs.sh)
            line="$(plain "$out" | grep -E '^docs: [0-9]+ references' | tail -1)"
            counted 7 "stage 10 (test-docs) references" "$(sed -nE 's/^docs: ([0-9]+) references.*/\1/p' <<<"$line")" "$(grep -c . "$par/plan.docs")"
            echo "plan: $(grep -c . "$par/plan.docs") references, as --list declares"
            ;;
    esac
}

report() { # <n> <stage title> <pass text> <fail text>
    stage "$2"
    if { [ "$1" = 5 ] && [ "$run_libs" -eq 0 ]; } || { [ "$1" = 6 ] && [ "$run_lang" -eq 0 ]; }; then
        echo "0 0 0" >"$par/$1.time"
        if [ "$1" = 6 ] && [ "$no_conformance" -eq 1 ]; then
            pass "$3 — not run: --no-conformance (decision 470)"
        else
            pass "$3 — skipped by the step gate: the step reaches no cell of it ($reach_why)"
        fi
        return 0
    fi
    cat "$par/$1.out"
    [ "$(cat "$par/$1.rc" 2>/dev/null)" = 0 ] || fail "$4"
    check_counts "$1"
    pass "$3 — $(stage_time "$par/$1.time")"
}
report 2 "zig build test-bpmp" "zig build test-bpmp" "zig build test-bpmp"
report 3 "beam export audit" "beam export audit" \
    "scripts/beam_export_audit.sh (a REJECTED block above names the module, function and reason)"
report 4 "zig build test-cli" "zig build test-cli" "zig build test-cli"
report 5 "zig build test-libs" "zig build test-libs" "zig build test-libs"
report 6 "zig build test-conformance" "zig build test-conformance" \
    "zig build test-conformance (a FAIL line above names the cell or the suite; a red cell's candidates and their differences follow it)"
report 7 "zig build test-docs" "zig build test-docs" \
    "zig build test-docs (a ✗ line above names the doc, the line and why)"
report 8 "tsc --noEmit over the emitted .d.ts, node --check over the emitted .js (scripts/tsc-check.sh)" "tsc-check" \
    "scripts/tsc-check.sh (the tsc error above names the project and the .d.ts; the defect is codegen/typescript.zig's)"
report 9 "zig build test-web (the compiler built for wasm32, smoke.js under node)" "zig build test-web" \
    "zig build test-web (a wasm32 compile error or a smoke.js assertion above names the defect)"

# Record the trees as green — only when nothing moved while the gate ran.
# Only the FULL gate records it: a step gate ran a subset of the cells, and the
# record lets a later `--staged` run on the same bytes — on `feat` — skip stages 2–11.
if [ "$gate_kind" = full ] && [ "$no_conformance" -eq 0 ] && [ "$(tree_key)" = "$start_key" ]; then
    echo "$start_key" >"$green_record"
fi

# ── § budget ─────────────────────────────────────────────────────────────────
# The whole run's wall clock (from the lock, so a wait for another gate is not
# counted) and the CPU-seconds of every stage, against the budget
# set on 16 idle cores (decision 265). Over budget is printed, never a red: a
# slow or shared machine is not a broken tree.
YELLOW='\033[0;33m'
wall=$(( $(date +%s) - gate_start ))
cpu="$(cat "$par"/*.time | tr ',' '.' | awk '{ c += $2 + $3 } END { printf "%.0f", c }')"
printf "\n${GREEN}gate: every stage passed — %s wall, %s CPU-s (budget %s)${NC}\n" \
    "$(fmt_time "$wall")" "$cpu" "$(fmt_time "$budget")"
if [ "$wall" -gt "$budget" ]; then
    printf "${YELLOW}gate: over budget — %s wall against %s; load %s${NC}\n" \
        "$(fmt_time "$wall")" "$(fmt_time "$budget")" "$(cut -d' ' -f1-3 /proc/loadavg 2>/dev/null || echo '?')"
fi
