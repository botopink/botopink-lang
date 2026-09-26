#!/usr/bin/env bash
# run.sh — the botopink language tests (fronts 15 and 17): decision 8's `case`,
# tuples and `loop`, plus the rest of the language surface — effects, comptime,
# decorators, externals, generics, closures, modules (`zig build test-language`).
#
# Usage:
#   tests/language/run.sh [--target commonJS|erlang|wasm|beam|all]
#                         [--compiler <botopink>]
#                         [--lib-root <dir>] [--only <path>] [--jobs <n>]
#
#   --target    default `all` (commonJS, erlang and wasm — the targets
#               `botopink run` executes directly). `beam` is supported and not
#               in `all`; see § beam below.
#   --compiler  the `botopink` binary; default <repo>/zig-out/bin/botopink
#   --lib-root  where `from "std"` resolves; default <compiler>/../../libs
#   --only      run one cell (e.g. test/case_arms.bp, modules/two_modules); may repeat
#   --jobs      parallel cells; default one per CPU, bounded by memory
#               (MemAvailable / 768 MiB) — § parallel cells below
#
# Four kinds, every cell in its own scratch project (a parse error fails only
# that cell):
#   test/<name>.bp     `botopink test --target <t> --json`; every test must pass
#   run/<name>.bp      `botopink run --target <t>`; stdout must equal <name>.out
#                      (on beam: run, then `erlc +from_asm out/*.S`, then `erl`).
#                      Three optional sidecars, each a claim about the cell:
#                        <name>.exit         `nonzero` — the program must abort:
#                                            stdout equals <name>.out AND the
#                                            status is not 0 (`@panic`, a failed
#                                            index). The number itself is never
#                                            pinned (escript 127 / erl 1 / wasmtime
#                                            134 / node 1 are the runtimes', not
#                                            the language's)
#                        <name>.<t>.expect   on target <t> the compiler must
#                                            REFUSE the program: exit non-zero and
#                                            the diagnostic contains line 1 (and
#                                            ` --> src/main.bp:<L:C>` when line 2 is
#                                            present) — the shape of reject/, per
#                                            target, for "no external target for
#                                            the active backend"
#                        <name>.targets      the targets the cell is scheduled on
#                                            (space-separated); absent = every
#                                            target of the run. A cell's header
#                                            comment says why a target is missing
#   reject/<name>.bp   `botopink check`; must exit non-zero, stderr must contain
#                      the first line of <name>.expect and ` --> src/main.bp:<L:C>`
#                      where <L:C> is its second line (target-independent: runs
#                      once, reported as target `*`)
#   modules/<name>/    a whole project — its own `botopink.json` and `src/` tree;
#                      `botopink run --target <t>`; stdout must equal
#                      <name>/expected.out — or, with <name>/<t>.expect, target
#                      <t> must REFUSE the project like a run/ cell's
#                      `.<t>.expect` (line 2 is `src/<file>.bp:<L:C>`). The kind for what one file cannot
#                      express: `pub mod`, `import … from "<module>"`, `from "std"`,
#                      and a local dependency — a second project inside the cell
#                      named by a `{ "path": "…" }` dependency of its manifest
#                      (front 12 step 4.2; no network, nothing special here)
#
# expected-failures.txt — one line per expected failure, `|`-separated (test
# names contain spaces):
#   <target: commonJS|erlang|wasm|beam|*> | <key> | <owner row> | <reason>
#
# <key> has three shapes, and which shape it is *is* part of the claim:
#   test/case_arms.bp                      the cell does not compile
#   test/case_guards.bp::<test>            it compiles; that one test fails
#   test/case_tuples.bp::<test> ;; <test>  it compiles; each of these fails
# ` ;; ` — one space either side — separates the names. `\|` anywhere on the line
# is a literal `|`: the split ignores an escaped pipe, which is how a test name
# that contains one is written (`Maybe<i32 \| string>`). Nothing else is escaped.
#
# Outcome rules (a run fails on any `FAIL`):
#   unlisted, passes            ok
#   unlisted, fails             FAIL
#   listed, fails               expected (printed with its owner)
#   listed, passes              FAIL — "now passes: delete its line" / "drop ::<test>"
#   listed, does not exist      FAIL — the path or the test name is not there
#   path-only entry on a file that compiles   FAIL — list the failing tests by name
#   malformed line              FAIL — the field, target or separator is named
#
# A named-test entry whose cell does **not** compile is still honoured: a cell that
# does not compile cannot pass anything, and the run prints the line with "the cell
# does not compile, so its listed tests did not run". That is the state the file is
# in while the front that makes the cell compile is in flight — seven fronts share
# this file and their compilers differ by hours. The path-only shape stays strict
# in both directions, which is what the five fronts reading it depend on.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(cd "$here/../.." && pwd)"

target="all"
compiler="$repo/zig-out/bin/botopink"
lib_root=""
jobs=""
only=()
while [ $# -gt 0 ]; do
    case "$1" in
        --target) target="$2"; shift 2 ;;
        --target=*) target="${1#*=}"; shift ;;
        --compiler) compiler="$2"; shift 2 ;;
        --compiler=*) compiler="${1#*=}"; shift ;;
        --lib-root) lib_root="$2"; shift 2 ;;
        --lib-root=*) lib_root="${1#*=}"; shift ;;
        --only) only+=("$2"); shift 2 ;;
        --only=*) only+=("${1#*=}"); shift ;;
        --jobs) jobs="$2"; shift 2 ;;
        --jobs=*) jobs="${1#*=}"; shift ;;
        -h|--help) sed -n '2,60p' "$0"; exit 0 ;;
        *) echo "run.sh: unknown argument '$1'" >&2; exit 2 ;;
    esac
done

# ── § parallel cells ─────────────────────────────────────────────────────────
# Every cell is its own scratch project and writes its verdict to its own
# `$work/r-<slug>` file; nothing is printed while cells run, and the verdicts are
# sorted before they are compared with expected-failures.txt. So how many cells
# run at once changes the wall clock and nothing else: `--jobs 1` and the default
# print the same bytes and exit with the same status.
#
# The pool is scripts/lib/pool.sh — `botopink-lib-test`'s rule: one cell per
# CPU, bounded by `MemAvailable / 768 MiB`, and a cell admitted only while the
# machine's runnable threads are at most the CPU count (other gates share it).
# shellcheck source=../../scripts/lib/pool.sh
. "$repo/scripts/lib/pool.sh"
[ -n "$jobs" ] || jobs="$(pool_default_jobs)"
pool_check_jobs "$jobs" run.sh

# ── § beam ────────────────────────────────────────────────────────────────────
# `botopink run --target beam` writes `out/*.S` and stops — BEAM Assembly is an
# artifact, not a run. It is two commands from being one (decision 8, measured at
# `c2dd780`):
#
#     $ botopink run --target beam        # wrote out/main.S
#     $ (cd out && erlc +from_asm *.S)    # main.S → main.beam
#     $ erl -noshell -pa out -eval "'language_tests@main':'_botopink_main'(), halt()."
#     hi
#
# `erlc` and `erl` are already gate dependencies (every erlang cell, and stage 5
# `scripts/beam_export_audit.sh`), so beam costs no new tool. `exec_run` below is
# that path, and `--target beam` runs it.
#
# `botopink test` refuses beam, so only run/ and modules/ cells reach it — the
# same rule wasm already lives under.
#
# beam is **not** in `all` yet, and that is scheduling, not doubt: front 13's
# policy 3 changes how many `.S` files a program emits and where they live, so a
# default-on runner would be written against a layout that is about to move, and
# every beam line of `expected-failures.txt` would be re-derived under it.
# Flipping it on is this one line — `all) targets=(commonJS erlang wasm beam)` —
# plus re-running the beam cells; do it as 13's closing step.
case "$target" in
    all) targets=(commonJS erlang wasm) ;;
    commonJS|erlang|wasm|beam) targets=("$target") ;;
    *) echo "run.sh: --target must be commonJS, erlang, wasm, beam or all (got '$target')" >&2; exit 2 ;;
esac
for t in "${targets[@]}"; do
    [ "$t" = "beam" ] || continue
    command -v erlc >/dev/null || { echo "run.sh: the beam target needs erlc" >&2; exit 2; }
    command -v erl  >/dev/null || { echo "run.sh: the beam target needs erl" >&2; exit 2; }
done
[ -x "$compiler" ] || { echo "run.sh: compiler not found or not executable: $compiler" >&2; exit 2; }
compiler="$(cd "$(dirname "$compiler")" && pwd)/$(basename "$compiler")"
[ -n "$lib_root" ] || lib_root="$(cd "$(dirname "$compiler")/../.." && pwd)/libs"
command -v node >/dev/null || { echo "run.sh: node is required" >&2; exit 2; }

work="$(mktemp -d "${TMPDIR:-/tmp}/bp-language-tests.XXXXXX")"
trap 'rm -rf "$work"' EXIT

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'; NC=$'\033[0m'

# ── collect the files ─────────────────────────────────────────────────────────
files=()
if [ ${#only[@]} -gt 0 ]; then
    files=("${only[@]}")
else
    while IFS= read -r f; do files+=("$f"); done < <(cd "$here" && { ls test/*.bp run/*.bp reject/*.bp 2>/dev/null; ls -d modules/*/ 2>/dev/null | sed 's:/$::'; } | sort)
fi

# ── one file, one target → result lines in $work/results ─────────────────────
#   <target>\t<key>\t<ok|fail>\t<detail>
# key is <path>::<test name> for test/ files, <path> otherwise; a test/ file
# that does not compile yields a single `<path>` line with status `fail`.
json_tests() {
    node -e '
      const lines = require("fs").readFileSync(0, "utf8").split("\n");
      for (const l of lines) {
        if (!l.startsWith("{")) continue;
        let e; try { e = JSON.parse(l); } catch { continue; }
        if (e.event !== "test") continue;
        const why = (e.error_message || "").replace(/[\t\n]/g, " ");
        process.stdout.write([e.name, e.status === "ok" ? "ok" : "fail", why].join("\t") + "\n");
      }'
}

strip() { sed -r 's/\x1b\[[0-9;]*m//g'; }
# progress lines (`Checking 1 module(s)...`) would satisfy an .expect like `..`
quiet() { strip | grep -vE '^[[:space:]]*(Checking|Checked|Compiling|Compiled) ' || true; }

# Run the project in <dir> on <target>: stdout in <dir>/stdout.txt, stderr in
# <dir>/e.txt, the program's exit status returned.
#
# Every target but beam is `botopink run`. beam stops at an artifact, so its path
# is three steps (§ beam at the top): compile, assemble **every** `out/*.S` with
# `erlc +from_asm` (a multi-module project emits one `.S` per module), then
# execute the entry module under `erl`. The compiler's own
# "wrote out/main.S — BEAM Assembly is an artifact" notice goes to stdout and is
# not program output, so it is kept out of the compared bytes.
exec_run() { # <dir> <target>
    local dir="$1" t="$2" mod=""
    if [ "$t" != "beam" ]; then
        (cd "$dir" && timeout 300 "$compiler" run --target "$t" >"$dir/stdout.txt" 2>"$dir/e.txt")
        return $?
    fi
    : >"$dir/stdout.txt"
    (cd "$dir" && timeout 300 "$compiler" run --target beam >"$dir/compile.txt" 2>"$dir/e.txt") || {
        cat "$dir/compile.txt" >>"$dir/e.txt"
        return 1
    }
    # Every `.S` under `out/`, not just the top level: today a `mod` tree and a
    # `from "std"` import emit nested directories (`out/shapes/circle.S`,
    # `out/std/…`), and a module left unassembled is an `undef` at run time, not
    # a compile error. `-o "$dir/out"` puts every `.beam` where `-pa out` looks,
    # which is also what front 13's policy 3 will make the emitter do by itself.
    while IFS= read -r s; do
        erlc +from_asm -o "$dir/out" "$s" || return 1
    done < <(find "$dir/out" -name '*.S' | sort) 2>>"$dir/e.txt"
    # The entry's atom starts with the package (decision 109): every cell's
    # botopink.json is named `language_tests`.
    if [ -f "$dir/out/language_tests@main.beam" ]; then
        mod=language_tests@main
    else
        mod="$(cd "$dir/out" && ls -1 ./*.beam 2>/dev/null | head -1)"
        mod="$(basename "${mod%.beam}")"
    fi
    [ -n "$mod" ] || { echo "error: erlc +from_asm produced no .beam" >>"$dir/e.txt"; return 1; }
    # The entry is `'_botopink_main'/0`, as for the codegen snapshots
    # (`runtime.executeBeamAsm`): it runs the module body — the `_` statements
    # and the effectful module-level `val`s, in declaration order — and then
    # `main/0`. Calling `main/0` directly skipped the module body.
    (cd "$dir" && timeout 300 erl -noshell -pa out -eval "'$mod':'_botopink_main'(), halt()." \
        >"$dir/stdout.txt" 2>>"$dir/e.txt")
}

project() { # <dir> <kind>
    mkdir -p "$1/src" "$1/test"
    printf '{ "name": "language_tests", "version": "0.0.1", "src": "src/", "targets": ["commonJS", "erlang", "wasm"] }\n' > "$1/botopink.json"
}

run_one() { # <path> <target>
    local path="$1" t="$2" slug dir out
    slug="$(printf '%s-%s' "$path" "$t" | tr '/.' '__')"
    dir="$work/p-$slug"; out="$work/r-$slug"
    rm -rf "$dir"
    case "$path" in
        modules/*) cp -R "$here/$path" "$dir" ;;
        *) project "$dir" ;;
    esac
    export BOTOPINK_LIB_ROOTS="$lib_root"
    case "$path" in
        test/*)
            cp "$here/$path" "$dir/test/$(basename "$path")"
            (cd "$dir" && timeout 300 "$compiler" test --target "$t" --json >"$dir/o.json" 2>"$dir/e.txt")
            json_tests <"$dir/o.json" >"$dir/tests.tsv"
            if [ ! -s "$dir/tests.tsv" ]; then
                local why; why="$(strip <"$dir/e.txt" | grep -m1 -E 'error' | tr '\t' ' ')"
                printf '%s\t%s\t%s\t%s\n' "$t" "$path" fail "does not compile: ${why:-no test ran}" >"$out"
            else
                : >"$out"
                while IFS=$'\t' read -r name status why; do
                    printf '%s\t%s::%s\t%s\t%s\n' "$t" "$path" "$name" "$status" "$why" >>"$out"
                done <"$dir/tests.tsv"
            fi ;;
        run/*)
            local expected="$here/${path%.bp}.out"
            local refuse="$here/${path%.bp}.$t.expect"
            local exitfile="$here/${path%.bp}.exit"
            cp "$here/$path" "$dir/src/main.bp"
            exec_run "$dir" "$t"
            local code=$?
            if [ -f "$refuse" ]; then
                # The claim is that this target refuses the program (the shape of
                # reject/, per target): non-zero, and the diagnostic named.
                quiet <"$dir/stdout.txt" >"$dir/all.txt"; quiet <"$dir/e.txt" >>"$dir/all.txt"
                local msg loc; msg="$(sed -n 1p "$refuse")"; loc="$(sed -n 2p "$refuse")"
                if [ $code -eq 0 ]; then
                    local got; got="$(head -c 300 "$dir/stdout.txt" | tr '\n\t' '⏎ ')"
                    printf '%s\t%s\t%s\t%s\n' "$t" "$path" fail "accepted (exit 0; stdout: $got); expected to be refused with: $msg" >"$out"
                elif ! grep -qF -- "$msg" "$dir/all.txt"; then
                    local first; first="$(grep -m1 -iE 'error' "$dir/all.txt" | tr '\t' ' ')"
                    printf '%s\t%s\t%s\t%s\n' "$t" "$path" fail "refused (exit $code), but not with \"$msg\" (got: ${first:-no error line})" >"$out"
                elif [ -n "$loc" ] && ! grep -qF -- "--> src/main.bp:$loc" "$dir/all.txt"; then
                    local where; where="$(grep -m1 -oE -- '--> src/main.bp:[0-9]+:[0-9]+' "$dir/all.txt")"
                    printf '%s\t%s\t%s\t%s\n' "$t" "$path" fail "right message, wrong location: ${where:-none} (expected $loc)" >"$out"
                else
                    printf '%s\t%s\t%s\t\n' "$t" "$path" ok >"$out"
                fi
            elif [ ! -f "$expected" ]; then
                printf '%s\t%s\t%s\t%s\n' "$t" "$path" fail "missing ${path%.bp}.out" >"$out"
            else
                # `<name>.exit` holding `nonzero` claims an abort: the program
                # prints its .out and then dies. Any other content is malformed.
                local want_exit=0
                if [ -f "$exitfile" ]; then
                    case "$(tr -d '[:space:]' <"$exitfile")" in
                        nonzero) want_exit=1 ;;
                        *) printf '%s\t%s\t%s\t%s\n' "$t" "$path" fail "malformed ${path%.bp}.exit: the only claim it can make is \`nonzero\`" >"$out"; return ;;
                    esac
                fi
                local status_ok=0
                if [ $want_exit -eq 0 ] && [ $code -eq 0 ]; then status_ok=1; fi
                if [ $want_exit -eq 1 ] && [ $code -ne 0 ]; then status_ok=1; fi
                if [ $status_ok -eq 1 ] && cmp -s "$dir/stdout.txt" "$expected"; then
                    printf '%s\t%s\t%s\t\n' "$t" "$path" ok >"$out"
                else
                    local got; got="$(head -c 300 "$dir/stdout.txt" | tr '\n\t' '⏎ ')"
                    local err; err="$(strip <"$dir/e.txt" | grep -m1 -iE 'error' | tr '\t' ' ')"
                    local want; want="exit $code"; [ $want_exit -eq 1 ] && [ $code -eq 0 ] && want="exit 0 where an abort was expected"
                    printf '%s\t%s\t%s\t%s\n' "$t" "$path" fail "$want; stdout: $got ${err:+; $err}" >"$out"
                fi
            fi ;;
        reject/*)
            local expect="$here/${path%.bp}.expect"
            cp "$here/$path" "$dir/src/main.bp"
            (cd "$dir" && timeout 300 "$compiler" check >"$dir/o.txt" 2>"$dir/e.txt")
            local code=$?
            quiet <"$dir/o.txt" >"$dir/all.txt"; quiet <"$dir/e.txt" >>"$dir/all.txt"
            if [ ! -f "$expect" ]; then
                printf '*\t%s\t%s\t%s\n' "$path" fail "missing ${path%.bp}.expect" >"$out"
            else
                local msg loc; msg="$(sed -n 1p "$expect")"; loc="$(sed -n 2p "$expect")"
                if [ $code -eq 0 ]; then
                    printf '*\t%s\t%s\t%s\n' "$path" fail "accepted (exit 0); expected: $msg" >"$out"
                elif ! grep -qF -- "$msg" "$dir/all.txt"; then
                    local first; first="$(grep -m1 -E '^error' "$dir/all.txt" | tr '\t' ' ')"
                    printf '*\t%s\t%s\t%s\n' "$path" fail "rejected, but not with \"$msg\" (got: ${first:-no error line})" >"$out"
                elif [ -n "$loc" ] && ! grep -qF -- "--> src/main.bp:$loc" "$dir/all.txt"; then
                    local where; where="$(grep -m1 -oE -- '--> src/main.bp:[0-9]+:[0-9]+' "$dir/all.txt")"
                    printf '*\t%s\t%s\t%s\n' "$path" fail "right message, wrong location: ${where:-none} (expected $loc)" >"$out"
                else
                    printf '*\t%s\t%s\t\n' "$path" ok >"$out"
                fi
            fi ;;
        modules/*)
            local expected="$here/$path/expected.out"
            local refuse="$here/$path/$t.expect"
            exec_run "$dir" "$t"
            local code=$?
            if [ -f "$refuse" ]; then
                # `<cell>/<target>.expect`: the run/ cell's `.<target>.expect`
                # claim for a whole project — this target refuses it.
                quiet <"$dir/stdout.txt" >"$dir/all.txt"; quiet <"$dir/e.txt" >>"$dir/all.txt"
                local msg loc; msg="$(sed -n 1p "$refuse")"; loc="$(sed -n 2p "$refuse")"
                if [ $code -eq 0 ]; then
                    printf '%s\t%s\t%s\t%s\n' "$t" "$path" fail "accepted (exit 0); expected to be refused with: $msg" >"$out"
                elif ! grep -qF -- "$msg" "$dir/all.txt"; then
                    local first; first="$(grep -m1 -iE 'error' "$dir/all.txt" | tr '\t' ' ')"
                    printf '%s\t%s\t%s\t%s\n' "$t" "$path" fail "refused (exit $code), but not with \"$msg\" (got: ${first:-no error line})" >"$out"
                elif [ -n "$loc" ] && ! grep -qF -- "--> $loc" "$dir/all.txt"; then
                    local where; where="$(grep -m1 -oE -- '--> src/[^ ]+:[0-9]+:[0-9]+' "$dir/all.txt")"
                    printf '%s\t%s\t%s\t%s\n' "$t" "$path" fail "right message, wrong location: ${where:-none} (expected $loc)" >"$out"
                else
                    printf '%s\t%s\t%s\t\n' "$t" "$path" ok >"$out"
                fi
            elif [ ! -f "$expected" ]; then
                printf '%s\t%s\t%s\t%s\n' "$t" "$path" fail "missing $path/expected.out" >"$out"
            elif [ $code -eq 0 ] && cmp -s "$dir/stdout.txt" "$expected"; then
                printf '%s\t%s\t%s\t\n' "$t" "$path" ok >"$out"
            else
                local got; got="$(head -c 300 "$dir/stdout.txt" | tr '\n\t' '⏎ ')"
                local err; err="$(strip <"$dir/e.txt" | grep -m1 -iE 'error' | tr '\t' ' ')"
                printf '%s\t%s\t%s\t%s\n' "$t" "$path" fail "exit $code; stdout: $got ${err:+; $err}" >"$out"
            fi ;;
        *) printf '*\t%s\t%s\t%s\n' "$path" fail "not under test/, run/, reject/ or modules/" >"$work/r-$slug" ;;
    esac
}
export -f run_one json_tests strip quiet project exec_run pool_job pool_admit pool_cpus
export here work compiler lib_root

# ── dispatch ──────────────────────────────────────────────────────────────────
jobs_list="$work/jobs"
: >"$jobs_list"
mkdir -p "$work/inflight"
for f in "${files[@]}"; do
    f="${f%/}"
    if [ ! -f "$here/$f" ] && [ ! -d "$here/$f" ]; then
        echo "run.sh: no such cell: $f" >&2; exit 2
    fi
    case "$f" in
        reject/*) printf '%s\t*\n' "$f" >>"$jobs_list" ;;
        # `botopink test` refuses every target but commonJS and erlang, so a
        # test/ cell never runs on wasm or beam (see AGENTS.md § the targets).
        test/*) for t in "${targets[@]}"; do
                    [ "$t" = "wasm" ] || [ "$t" = "beam" ] && continue
                    printf '%s\t%s\n' "$f" "$t" >>"$jobs_list"
                done ;;
        run/*)  # `<name>.targets` narrows the cell to the targets it claims
                local_targets=("${targets[@]}")
                if [ -f "$here/${f%.bp}.targets" ]; then
                    read -r -a declared <"$here/${f%.bp}.targets"
                    local_targets=()
                    for t in "${targets[@]}"; do
                        for d in "${declared[@]}"; do [ "$t" = "$d" ] && local_targets+=("$t"); done
                    done
                fi
                for t in "${local_targets[@]}"; do printf '%s\t%s\n' "$f" "$t" >>"$jobs_list"; done ;;
        *) for t in "${targets[@]}"; do printf '%s\t%s\n' "$f" "$t" >>"$jobs_list"; done ;;
    esac
done
while IFS=$'\t' read -r f t; do
    if [ "$t" = "*" ]; then printf '%s\0%s\0' "$f" "${targets[0]}"; else printf '%s\0%s\0' "$f" "$t"; fi
done <"$jobs_list" | xargs -0 -n 2 -P "$jobs" bash -c 'pool_job "$work/inflight" run_one "$0" "$1"'

cat "$work"/r-* 2>/dev/null | sort >"$work/results"

# ── compare with expected-failures.txt ────────────────────────────────────────
node - "$work/results" "$here/expected-failures.txt" "${targets[*]}" "${#only[@]}" <<'EOF'
const fs = require("fs");
const [resultsPath, listPath, targetsArg, onlyCount] = process.argv.slice(2);
const targets = targetsArg.split(" ");
const partial = Number(onlyCount) > 0;
const RED = "\x1b[0;31m", GREEN = "\x1b[0;32m", YELLOW = "\x1b[0;33m", NC = "\x1b[0m";

const results = new Map(); // `${target}\t${key}` -> {status, detail}
const compiled = new Set(); // `${target}\t${path}` for test/ files that produced test events
for (const line of fs.readFileSync(resultsPath, "utf8").split("\n")) {
  if (!line) continue;
  const [t, key, status, detail] = line.split("\t");
  results.set(`${t}\t${key}`, { status, detail: detail || "" });
  if (key.includes("::")) compiled.add(`${t}\t${key.split("::")[0]}`);
}

// A line is split on `|` only where the `|` is not escaped: `\\|` is a literal
// pipe, which is how a test name that contains one is written. Nothing else is
// escaped. The key field then has one of three shapes — <path>, <path>::<test>,
// or <path>::<test> ;; <test> — and a line that is none of them is a FAIL that
// names what is wrong with it, never a line read as a different shape.
const TARGETS = ["commonJS", "erlang", "wasm", "beam", "*"];
const unescapePipe = (s) => s.replace(/\\\|/g, "|");
const expected = [];
if (fs.existsSync(listPath)) {
  fs.readFileSync(listPath, "utf8").split("\n").forEach((raw, i) => {
    const line = raw.trim();
    if (!line || line.startsWith("#")) return;
    const bad = (why) => expected.push({ bad: `expected-failures.txt:${i + 1}: ${why}` });
    const parts = line.split(/(?<!\\)\|/).map((s) => unescapePipe(s.trim()));
    if (parts.length < 4 || !parts[0] || !parts[1] || !parts[2] || !parts[3]) {
      bad("needs 4 non-empty fields — <target> | <path>[::<test>[ ;; <test>]] | <owner row> | <reason>");
      return;
    }
    const [target, keyField, owner] = parts;
    if (!TARGETS.includes(target)) {
      bad(`unknown target \`${target}\` — one of ${TARGETS.join(", ")}`);
      return;
    }
    const cut = keyField.indexOf("::");
    const path = (cut < 0 ? keyField : keyField.slice(0, cut)).trim();
    if (!path) { bad("the path is empty"); return; }
    let tests = null;
    if (cut >= 0) {
      if (!path.startsWith("test/")) {
        bad(`\`::\` names a test and only a test/ cell has tests — got \`${path}\``);
        return;
      }
      tests = keyField.slice(cut + 2).split(" ;; ").map((t) => t.trim());
      if (tests.some((t) => !t)) {
        bad("an empty test name — the separator between names is ` ;; `, one space either side");
        return;
      }
      if (new Set(tests).size !== tests.length) { bad("the same test name twice on one line"); return; }
    }
    expected.push({ target, path, tests, owner, reason: parts.slice(3).join(" | "), line: i + 1 });
  });
}

// Decision 59 (b) of `specs/1.0.5-beta/decisions-taken.md`: the tally of
// expected-failures.txt is printed by the runner, recounted from the file on
// every run, and never kept by hand in the file's header. The owner field is
// split on `,` outside parentheses — `02 (no step; decision 55, reported …)`
// is one row — and the first token of the first row names the owner.
if (!partial) {
  const live = expected.filter((e) => !e.bad);
  const byTarget = new Map(), byOwner = new Map();
  let named = 0, second = 0, exercised = 0;
  for (const e of live) {
    byTarget.set(e.target, (byTarget.get(e.target) || 0) + 1);
    const rows = e.owner.split(/,(?![^(]*\))/).map((s) => s.trim()).filter(Boolean);
    const first = (rows[0] || "?").split(/\s+/)[0];
    byOwner.set(first, (byOwner.get(first) || 0) + 1);
    if (rows.length > 1) second++;
    if (e.tests) named++;
    if (e.target === "*" || targets.includes(e.target)) exercised++;
  }
  const fmt = (m) => [...m.entries()].sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0])).map(([k, v]) => `${k} ${v}`).join(" · ");
  console.log(`expected-failures.txt: ${live.length} lines, ${exercised} exercised by --target ${targetsArg.replace(/ /g, ",")} — by target: ${fmt(byTarget)}; by first owner row: ${fmt(byOwner)}; ${named} name tests rather than a path; ${second} name a second row`);
}

let fails = 0, oks = 0, expectedCount = 0;
const out = [];
const claimed = new Set();
for (const e of expected) {
  if (e.bad) { out.push(`${RED}FAIL${NC}     ${e.bad}`); fails++; continue; }
  const ts = e.target === "*" ? ["*", ...targets] : [e.target];
  if (e.target !== "*" && !targets.includes(e.target)) continue; // not run this time
  const at = `expected-failures.txt:${e.line}`;
  let found = false;
  for (const t of ts) {
    // Shape 1 — path only: the claim is that the cell does not compile, and it is
    // strict in both directions. Five fronts read this shape; nothing below widens it.
    if (e.tests === null) {
      if (compiled.has(`${t}\t${e.path}`)) {
        found = true;
        out.push(`${RED}FAIL${NC}     [${t}] ${e.path} — compiles: list its failing tests by name (${at})`);
        fails++;
        continue;
      }
      const r = results.get(`${t}\t${e.path}`);
      if (!r) continue;
      found = true;
      claimed.add(`${t}\t${e.path}`);
      if (r.status === "ok") {
        out.push(`${RED}FAIL${NC}     [${t}] ${e.path} — now passes: delete its line (${at})`);
        fails++;
      } else {
        out.push(`${YELLOW}expected${NC} [${t}] ${e.path} — ${e.owner}: ${e.reason}`);
        expectedCount++;
      }
      continue;
    }
    // Shapes 2 and 3 — one or more named tests: the claim is that none of them
    // passes. A cell that does not compile at all passes nothing, so the line is
    // honoured and the run says so; that is the state the file is in while the
    // front that makes the cell compile is in flight.
    if (!compiled.has(`${t}\t${e.path}`)) {
      const r = results.get(`${t}\t${e.path}`);
      if (!r) continue;
      found = true;
      claimed.add(`${t}\t${e.path}`);
      const n = e.tests.length;
      out.push(`${YELLOW}expected${NC} [${t}] ${e.path} — ${e.owner}: ${e.reason} ${YELLOW}[the cell does not compile, so its ${n} listed test${n === 1 ? "" : "s"} did not run: ${r.detail}]${NC}`);
      expectedCount++;
      continue;
    }
    found = true;
    let stillFailing = 0;
    for (const name of e.tests) {
      const r = results.get(`${t}\t${e.path}::${name}`);
      if (!r) {
        out.push(`${RED}FAIL${NC}     [${t}] ${e.path} — no test named "${name}" (${at})`);
        fails++;
        continue;
      }
      claimed.add(`${t}\t${e.path}::${name}`);
      if (r.status === "ok") {
        out.push(`${RED}FAIL${NC}     [${t}] ${e.path} — "${name}" now passes: drop it from the line, and delete the line when it names no other (${at})`);
        fails++;
      } else stillFailing++;
    }
    if (stillFailing) {
      const names = e.tests.length === 1 ? e.tests[0] : `${stillFailing} of ${e.tests.length} tests`;
      out.push(`${YELLOW}expected${NC} [${t}] ${e.path} — ${names} — ${e.owner}: ${e.reason}`);
      expectedCount++;
    }
  }
  if (!found) {
    const fileRan = [...results.keys()].some((k) => k.split("\t")[1].split("::")[0] === e.path);
    if (partial && !fileRan) continue; // --only run that skipped this file
    out.push(`${RED}FAIL${NC}     ${e.path} — listed (line ${e.line}) but no such ${e.tests && fileRan ? "test" : "file or result"} for target ${e.target}`);
    fails++;
  }
}
for (const [k, r] of results) {
  if (claimed.has(k)) continue;
  const [t, key] = k.split("\t");
  if (r.status === "ok") { oks++; continue; }
  out.push(`${RED}FAIL${NC}     [${t}] ${key} — ${r.detail}`);
  fails++;
}
for (const l of out) console.log(l);
const colour = fails ? RED : GREEN;
console.log(`\n${colour}language tests: ${oks} passed, ${expectedCount} expected failures, ${fails} failed${NC}`);
process.exit(fails ? 1 : 0);
EOF
