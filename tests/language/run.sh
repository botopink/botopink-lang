#!/usr/bin/env bash
# run.sh — the botopink language tests (fronts 15 and 17): decision 8's `case`,
# tuples and `loop`, plus the rest of the language surface — effects, comptime,
# decorators, externals, generics, closures, modules (`zig build test-language`).
#
# Usage:
#   tests/language/run.sh [--target commonJS|erlang|wasm|beam|all]
#                         [--compiler <botopink>]
#                         [--lib-root <dir>] [--only <path>] [--jobs <n>] [--list]
#   tests/language/run.sh --self-test [--compiler <botopink>] [--lib-root <dir>]
#
#   --target    default `all`: commonJS, erlang, wasm and beam — every target
#               `botopink run` executes. A missing runtime fails the run; it
#               never drops a target (decision 67).
#   --compiler  the `botopink` binary; default <repo>/zig-out/bin/botopink
#   --lib-root  where `from "std"` resolves; default <compiler>/../../libs
#   --only      run one cell (e.g. test/case_arms.bp, modules/two_modules); may repeat
#   --jobs      parallel cells; default one per CPU, bounded by memory
#               (MemAvailable / 768 MiB) — § parallel cells below
#   --list      print the plan and run nothing: one `<path>\t<target>\t<run|audit>`
#               line per job (a `reject/` cell's target is `*`). A whole run
#               ends with `cells: <J> jobs — <R> run, <A> audits`, and
#               `scripts/gate.sh` holds J to the number of lines `--list`
#               prints: a run cannot do fewer jobs than the tree declares
#   --suite     the directory holding test/, run/, reject/ and modules/; default
#               this script's own. `--self-test` is its one caller.
#   --self-test prove § the targets of a cell against synthetic cells: a
#               narrowing the compiler does not back fails the run, one it backs
#               schedules the cell on the declared targets alone. A whole run of
#               the suite (no --only) starts with it.
#   --cold      run every job; the result store is not read, and the passes are
#               written to it (§ the result store); `scripts/gate.sh --cold`
#               passes it
#   --store-root  the result store's directory; default
#               <repo>/.botopinkbuild/cache/results/language
#
# Four kinds, every cell in its own scratch project (a parse error fails only
# that cell):
#   test/<name>.bp     `botopink test --target <t> --json`; every test must pass
#   run/<name>.bp      `botopink run --target <t>`; stdout must equal <name>.out.
#                      Four optional sidecars, each a claim about the cell:
#                        <name>.exit         `nonzero` — the program must abort:
#                                            stdout equals <name>.out AND the
#                                            status is not 0 (`@panic`, a failed
#                                            index). The number itself is never
#                                            pinned (escript 127 / erl 1 / wasmtime
#                                            134 / node 1 are the runtimes', not
#                                            the language's)
#                        <name>.<t>.stderr   with `.exit`: on target <t> the abort's
#                                            stderr contains line 1 (`integer
#                                            overflow: + on i32 at src/main.bp:2:14`)
#                                            — what the program died of, not
#                                            only that it died
#                        <name>.<t>.expect   on target <t> the compiler must
#                                            REFUSE the program: exit non-zero and
#                                            the diagnostic contains line 1 (and
#                                            ` --> src/main.bp:<L:C>` when line 2 is
#                                            present) — the shape of reject/, per
#                                            target, for "no external target for
#                                            the active backend"
#                        <name>.targets      the targets the cell is scheduled on
#                                            (space-separated); absent = every
#                                            target of the run. Audited on every
#                                            run — § the targets of a cell
#   reject/<name>.bp   `botopink check`; must exit non-zero, stderr must contain
#                      the first line of <name>.expect and ` --> src/main.bp:<L:C>`
#                      where <L:C> is its second line — required: every refusal
#                      is located (C-21) (target-independent: runs once,
#                      reported as target `*`)
#   modules/<name>/    a whole project — its own `botopink.json` and `src/` tree;
#                      `botopink run --target <t>`; stdout must equal
#                      <name>/expected.out — or, with <name>/<t>.expect, target
#                      <t> must REFUSE the project like a run/ cell's
#                      `.<t>.expect` (line 2 is `src/<file>.bp:<L:C>`). The kind for what one file cannot
#                      express: `pub mod`, `import … from "<module>"`, `from "std"`,
#                      and a local dependency — a second project inside the cell
#                      named by a `{ "path": "…" }` dependency of its manifest
#                      (front 12 step 4.2; no network, nothing special here).
#                      A project cell with a `test/` tree and no expected.out is
#                      the test/ kind over the project: `botopink test --target
#                      <t> --json` (commonJS, erlang and beam), keyed <name>::<test>.
#                      `"targets"` in the cell's botopink.json narrows it the
#                      way `<name>.targets` narrows a run/ cell, and is audited
#                      the same way — § the targets of a cell
#
# Outcome rules: a cell passes or it fails, and a run fails on any `FAIL`. There
# is no list of known failures (gate-b of `specs/1.0.11-beta/00-gate`, decision
# 154): a red cell is red until the compiler passes it.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(cd "$here/../.." && pwd)"

target="all"
compiler="$repo/zig-out/bin/botopink"
lib_root=""
jobs=""
only=()
suite=""
self_test=0
list=0
cold=0
store_dir=""
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
        --suite) suite="$2"; shift 2 ;;
        --suite=*) suite="${1#*=}"; shift ;;
        --self-test) self_test=1; shift ;;
        --list) list=1; shift ;;
        --cold) cold=1; shift ;;
        --store-root) store_dir="$2"; shift 2 ;;
        --store-root=*) store_dir="${1#*=}"; shift ;;
        -h|--help) sed -n '2,74p' "$0"; exit 0 ;;
        *) echo "run.sh: unknown argument '$1'" >&2; exit 2 ;;
    esac
done
runner="$here/$(basename "${BASH_SOURCE[0]}")"
# The cells are read from `$here`; `--suite` points it at another tree.
whole_suite=0
if [ -n "$suite" ]; then
    [ -d "$suite" ] || { echo "run.sh: --suite is not a directory: $suite" >&2; exit 2; }
    here="$(cd "$suite" && pwd)"
elif [ ${#only[@]} -eq 0 ] && [ $self_test -eq 0 ] && [ $list -eq 0 ]; then
    whole_suite=1
fi

# ── § parallel cells ─────────────────────────────────────────────────────────
# Every cell is its own scratch project and writes its verdict to its own
# `$work/r-<slug>` file; nothing is printed while cells run, and the verdicts are
# sorted before they are reported. So how many cells run at once changes the wall
# clock and nothing else: `--jobs 1` and the default print the same bytes and
# exit with the same status.
#
# The pool is scripts/lib/pool.sh — `botopink-lib-test`'s rule: one cell per
# CPU, bounded by `MemAvailable / 768 MiB`, and a cell admitted only while the
# machine's runnable threads are at most the CPU count (other gates share it).
# shellcheck source=../../scripts/lib/pool.sh
. "$repo/scripts/lib/pool.sh"
[ -n "$jobs" ] || jobs="$(pool_default_jobs)"
pool_check_jobs "$jobs" run.sh

# ── § beam ────────────────────────────────────────────────────────────────────
# `botopink run --target beam` is a run like the other three: it builds
# `out/beam/*.S`, assembles each beside itself and executes the entry —
#
#     $ botopink run --target beam
#     # = botopink build --target beam
#     #   erlc +from_asm -o out/beam out/beam/*.S
#     #   erl -noshell -pa out/beam -eval "'language_tests@main':main([]), halt()."
#     hi
#
# — so `exec_run` below has one arm. The `.beam`s sit beside the `.S` files
# because that is where the build ships a host `.erl` (`#[@External.Erlang]`'s
# module, `modules/erlang_host_sidecar_shipped`) and where the entry's
# `'__bp_load_siblings'/0` compiles and loads it from.
#
# `erlc` and `erl` are gate dependencies already (every erlang cell, and
# `scripts/beam_export_audit.sh`), so beam costs no new tool; a machine without
# them fails the run below rather than run three targets and say "all".
#
# `botopink test --target beam` assembles every module of the run beside
# itself and runs each test module's runner with `erl -pa`, so test/ cells
# and test-kind modules/ cells run on beam too; `botopink test` refuses wasm
# alone, so only run/ and modules/ cells reach wasm.
#
# ── § the targets of a cell ───────────────────────────────────────────────────
# A cell runs on every target its kind has — test/ and a test-kind modules/
# cell on commonJS, erlang and beam (`botopink test` runs nowhere else), run/
# and a modules/ cell on all four — unless it NARROWS itself: `run/<name>.targets`
# (space-separated) or `"targets"` in `modules/<name>/botopink.json`.
#
# A narrowing is a claim about the compiler, and the runner checks it on every
# run (gate-d of `specs/1.0.11-beta/00-gate`): for each target of the run the
# cell excludes, `botopink build --target <t>` in the cell must REFUSE the
# program on a host binding —
#
#     `f` has no `#[@External.<Target>(…)]` for the <t> backend
#     std-unsupported-on-target: std/<m> has no `#[@External.<Target>]` for target '<t>'
#
#     `#[@BeamMemory]` has no meaning on the <t> backend
#
# — the one reason a program structurally has no row on a target (the third
# line is decision 167's: a module `var` under `#[@BeamMemory.<mode>]` binds
# BEAM storage, which commonJS and wasm refuse at the annotation). A target the
# build accepts, or refuses for any other reason, fails the run naming the cell: the narrowing was hiding a gap of that backend, and a gap is a row of
# the backend's front, not a line in a `.targets` file. So is a narrowing that
# names a target its kind does not have, an unknown one, the same one twice, or
# every target of the kind (it narrows nothing: delete it). No flag, list or
# environment variable turns the audit off (decision 67); `--self-test` shows
# each refusal firing.
#
# A target a cell must be REFUSED on for a reason of its own — the claim is the
# diagnostic — is not narrowed away: it is pinned with `<name>.<t>.expect`.
ALL_TARGETS="commonJS erlang wasm beam"
case "$target" in
    all) targets=(commonJS erlang wasm beam) ;;
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

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; NC=$'\033[0m'

# ── § self-test ───────────────────────────────────────────────────────────────
# § the targets of a cell, shown firing. A synthetic suite — two narrowings the
# compiler backs with a host-binding refusal, and one of each way a narrowing
# is refused — is run through this script (`--suite`), and the report it prints
# must hold exactly these lines. A runner whose audit stopped refusing would
# print a green run over a narrowed suite; this is what reds instead.
self_test() {
    local st="$work/self-test" suite="$work/self-test/suite" missing=0 line
    mkdir -p "$suite/run"
    cell() { # <run cell name> <targets> — source on stdin, `.out` = `ok`
        cat >"$suite/run/$1.bp"
        printf 'ok\n' >"$suite/run/$1.out"
        printf '%s\n' "$2" >"$suite/run/$1.targets"
    }
    project_cell() { # <modules cell name> <"targets" JSON> — src/main.bp on stdin
        mkdir -p "$suite/modules/$1/src"
        cat >"$suite/modules/$1/src/main.bp"
        printf '{ "name": "language_tests", "version": "0.0.1", "src": "src/", "targets": %s }\n' "$2" >"$suite/modules/$1/botopink.json"
        printf 'ok\n' >"$suite/modules/$1/expected.out"
    }
    # Backed: node binds the function, so erlang, wasm and beam refuse it.
    cell backed "commonJS" <<'BP'
#[@External.Node("""("ok")""")]
declare fn host() -> string;

pub fn main() {
    @print(host());
}
BP
    # Unbacked: nothing about the program is a host's, and wasm builds it.
    cell unbacked "commonJS erlang beam" <<'BP'
pub fn main() {
    @print("ok");
}
BP
    # Refused, but not on a host binding: no target compiles an unbound name.
    cell refused_for_another_reason "commonJS erlang beam" <<'BP'
pub fn main() {
    @print(nowhere);
}
BP
    # Decision 167: BEAM storage is a binding commonJS and wasm refuse …
    cell beam_memory_backed "erlang beam" <<'BP'
#[@BeamMemory.ProcessDict]
var seen: i32 = 0;

pub fn main() {
    seen = 1;
    @print("ok");
}
BP
    # … and one the BEAM has: the annotation never excuses erlang or beam.
    cell beam_memory_excludes_beam "erlang" <<'BP'
#[@BeamMemory.ProcessDict]
var seen: i32 = 0;

pub fn main() {
    seen = 1;
    @print("ok");
}
BP
    cell narrows_nothing "commonJS erlang wasm beam" <<'BP'
pub fn main() {
    @print("ok");
}
BP
    cell unknown_target "commonJS jvm" <<'BP'
pub fn main() {
    @print("ok");
}
BP
    # Backed, by manifest: the BEAM binds the function, commonJS and wasm refuse it.
    project_cell manifest_backed '["erlang", "beam"]' <<'BP'
#[@External.Erlang("""<<"ok">>""")]
declare fn host() -> string;

pub fn main() {
    @print(host());
}
BP
    project_cell manifest_unbacked '["commonJS", "erlang"]' <<'BP'
pub fn main() {
    @print("ok");
}
BP
    # A test-kind project cell never runs on wasm: naming it is malformed.
    project_cell manifest_test_kind '["commonJS", "wasm"]' <<'BP'
pub fn one() -> i32 {
    return 1;
}
BP
    rm "$suite/modules/manifest_test_kind/expected.out"
    mkdir -p "$suite/modules/manifest_test_kind/test"
    cat >"$suite/modules/manifest_test_kind/test/one_test.bp" <<'BP'
import {one} from "main";

test "one" {
    assert one() == 1;
}
BP

    # `--cold`: the runner's own proof runs every synthetic cell, every time,
    # and what it passes goes to a store of its own, deleted with the run.
    bash "$runner" --suite "$suite" --target all --compiler "$compiler" --lib-root "$lib_root" --jobs "$jobs" --cold \
        --store-root "$st/store" >"$st/raw.txt" 2>&1
    local code=$?
    strip <"$st/raw.txt" >"$st/report.txt"
    [ $code -eq 1 ] || { echo "self-test: the synthetic suite exited $code, expected 1" >&2; missing=1; }
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        grep -qF -- "$line" "$st/report.txt" || { echo "self-test: the report lacks: $line" >&2; missing=1; }
    done <<'WANT'
[wasm] run/unbacked.bp — excluded by run/unbacked.targets, but `botopink build --target wasm` accepts the cell
[wasm] run/refused_for_another_reason.bp — excluded by run/refused_for_another_reason.targets, and wasm refuses it for another reason than a host binding
[beam] run/beam_memory_excludes_beam.bp — excluded by run/beam_memory_excludes_beam.targets, but `botopink build --target beam` accepts the cell
[*] run/narrows_nothing.bp — run/narrows_nothing.targets names every target the cell runs on, so it narrows nothing
[*] run/unknown_target.bp — run/unknown_target.targets names `jvm`, which is no target
[wasm] modules/manifest_unbacked — excluded by modules/manifest_unbacked/botopink.json "targets", but `botopink build --target wasm` accepts the cell
[beam] modules/manifest_unbacked — excluded by modules/manifest_unbacked/botopink.json "targets", but `botopink build --target beam` accepts the cell
[*] modules/manifest_test_kind — modules/manifest_test_kind/botopink.json "targets" names wasm, a target this kind of cell never runs on
narrowings: 9 exclusions audited
by target: commonJS 3/4 · erlang 5/6 · wasm 0/3 · beam 3/6 · * 0/3
language tests: 11 passed, 11 failed
WANT
    # The three backed cells ran where they said and nowhere else: the tally
    # above counts them (1 + 2 + 2 of the 11), and no line may name them.
    if grep -qE 'run/backed\.bp|run/beam_memory_backed\.bp|modules/manifest_backed' "$st/report.txt"; then
        echo "self-test: a narrowing that stands on a host binding was reported:" >&2
        grep -E 'run/backed\.bp|run/beam_memory_backed\.bp|modules/manifest_backed' "$st/report.txt" >&2
        missing=1
    fi
    if [ $missing -ne 0 ]; then
        echo "self-test: FAILED — the synthetic suite's report was:" >&2
        sed 's/^/    /' "$st/report.txt" >&2
        return 1
    fi
    echo "self-test: 8 malformed or unbacked narrowings refused, 3 backed ones scheduled on their declared targets alone"
}

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

strip() { sed "s/$(printf '\033')\[[0-9;]*m//g"; }
# progress lines (`Checking 1 module(s)...`) would satisfy an .expect like `..`
quiet() { strip | grep -vE '^[[:space:]]*(Checking|Checked|Compiling|Compiled) ' || true; }

# Run the project in <dir> on <target>: stdout in <dir>/stdout.txt, stderr in
# <dir>/e.txt, the program's exit status returned. Every target is
# `botopink run` — on beam that is build, `erlc +from_asm` beside the `.S`, and
# `erl` on that directory (§ beam at the top).
exec_run() { # <dir> <target>
    local dir="$1" t="$2"
    (cd "$dir" && with_timeout 300 "$compiler" run --target "$t" >"$dir/stdout.txt" 2>"$dir/e.txt")
}

project() { # <dir> <kind>
    mkdir -p "$1/src" "$1/test"
    printf '{ "name": "language_tests", "version": "0.0.1", "src": "src/" }\n' > "$1/botopink.json"
}

# `botopink test --json` in <dir>; one result line per test, keyed <path>::<name>,
# or one `fail` line for <path> when nothing ran.
test_project() { # <dir> <path> <target> <out>
    local dir="$1" path="$2" t="$3" out="$4"
    (cd "$dir" && with_timeout 300 "$compiler" test --target "$t" --json >"$dir/o.json" 2>"$dir/e.txt")
    json_tests <"$dir/o.json" >"$dir/tests.tsv"
    if [ ! -s "$dir/tests.tsv" ]; then
        local why; why="$(strip <"$dir/e.txt" | grep -m1 -E 'error' | tr '\t' ' ')"
        printf '%s\t%s\t%s\t%s\n' "$t" "$path" fail "does not compile: ${why:-no test ran}" >"$out"
    else
        : >"$out"
        while IFS=$'\t' read -r name status why; do
            printf '%s\t%s::%s\t%s\t%s\n' "$t" "$path" "$name" "$status" "$why" >>"$out"
        done <"$dir/tests.tsv"
    fi
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
            test_project "$dir" "$path" "$t" "$out" ;;
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
                # `<name>.<t>.stderr` names the abort on target <t>: line 1 must
                # be in its stderr. It only qualifies an `.exit` claim.
                local errfile="$here/${path%.bp}.$t.stderr"
                if [ -f "$errfile" ] && [ $want_exit -eq 0 ]; then
                    printf '%s\t%s\t%s\t%s\n' "$t" "$path" fail "${path%.bp}.$t.stderr names an abort, but no ${path%.bp}.exit claims one" >"$out"; return
                fi
                local status_ok=0
                if [ $want_exit -eq 0 ] && [ $code -eq 0 ]; then status_ok=1; fi
                if [ $want_exit -eq 1 ] && [ $code -ne 0 ]; then status_ok=1; fi
                local abort_msg=""
                [ -f "$errfile" ] && abort_msg="$(sed -n 1p "$errfile")"
                if [ $status_ok -eq 1 ] && [ -n "$abort_msg" ] && cmp -s "$dir/stdout.txt" "$expected" && ! strip <"$dir/e.txt" | grep -qF -- "$abort_msg"; then
                    local first; first="$(strip <"$dir/e.txt" | grep -m1 -iE 'error|trap' | tr '\t' ' ')"
                    printf '%s\t%s\t%s\t%s\n' "$t" "$path" fail "aborted (exit $code), but stderr does not name \"$abort_msg\" (got: ${first:-nothing})" >"$out"
                elif [ $status_ok -eq 1 ] && cmp -s "$dir/stdout.txt" "$expected"; then
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
            (cd "$dir" && with_timeout 300 "$compiler" check >"$dir/o.txt" 2>"$dir/e.txt")
            local code=$?
            quiet <"$dir/o.txt" >"$dir/all.txt"; quiet <"$dir/e.txt" >>"$dir/all.txt"
            if [ ! -f "$expect" ]; then
                printf '*\t%s\t%s\t%s\n' "$path" fail "missing ${path%.bp}.expect" >"$out"
            else
                local msg loc; msg="$(sed -n 1p "$expect")"; loc="$(sed -n 2p "$expect")"
                if [ -z "$loc" ]; then
                    # C-21: every refusal is located, so every reject cell pins where.
                    printf '*\t%s\t%s\t%s\n' "$path" fail "${path%.bp}.expect names no location (line 2, <L:C>)" >"$out"
                elif [ $code -eq 0 ]; then
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
            # A project cell with a `test/` tree and no `expected.out` is the
            # test/ kind over a whole project: `botopink test`, every test ok.
            # (One arm, not a `;;&` fall-through: macOS's bash 3.2 has none.)
            if [ -d "$here/$path/test" ] && [ ! -f "$here/$path/expected.out" ]; then
                test_project "$dir" "$path" "$t" "$out"
                return
            fi
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
# One exclusion of a narrowed cell, audited (§ the targets of a cell): build the
# cell on the target it excludes and require a host-binding refusal. Result
# status `audit` on a refusal the narrowing may stand on, `fail` otherwise.
audit_one() { # <path> <excluded target> <the file that narrows>
    local path="$1" t="$2" by="$3" slug dir out
    slug="$(printf '%s-%s' "$path" "$t" | tr '/.' '__')"
    dir="$work/x-$slug"; out="$work/r-audit-$slug"
    rm -rf "$dir"
    case "$path" in
        modules/*) cp -R "$here/$path" "$dir" ;;
        *) project "$dir"; cp "$here/$path" "$dir/src/main.bp" ;;
    esac
    export BOTOPINK_LIB_ROOTS="$lib_root"
    (cd "$dir" && with_timeout 300 "$compiler" build --target "$t" >"$dir/o.txt" 2>"$dir/e.txt")
    local code=$?
    quiet <"$dir/o.txt" >"$dir/all.txt"; quiet <"$dir/e.txt" >>"$dir/all.txt"
    if [ $code -eq 0 ]; then
        printf '%s\t%s\t%s\t%s\n' "$t" "$path" fail "excluded by $by, but \`botopink build --target $t\` accepts the cell — a narrowing stands on a host-binding refusal: let it run on $t, and a red there is a row of that backend's front" >"$out"
    elif grep -qF -e 'has no `#[@External.<Target>(' -e 'std-unsupported-on-target:' -e '`#[@BeamMemory]` has no meaning on the '"$t"' backend' "$dir/all.txt"; then
        printf '%s\t%s\t%s\t\n' "$t" "$path" audit >"$out"
    else
        local first; first="$(grep -m1 -iE 'error' "$dir/all.txt" | tr '\t' ' ')"
        printf '%s\t%s\t%s\t%s\n' "$t" "$path" fail "excluded by $by, and $t refuses it for another reason than a host binding (got: ${first:-no error line}) — pin a refusal with a .$t.expect, or let the cell run there" >"$out"
    fi
}
export -f run_one test_project json_tests strip quiet project exec_run audit_one pool_job pool_admit pool_cpus with_timeout
export here work compiler lib_root

if [ $self_test -eq 1 ]; then
    self_test; exit $?
fi
# A whole run of the suite proves its own audit first: a green run from a
# runner that no longer refuses says nothing.
if [ $whole_suite -eq 1 ]; then
    self_test || exit 1
fi

# ── dispatch ──────────────────────────────────────────────────────────────────
# One line per job: <path>\t<target>\t<run | audit:<narrowing file>>.
jobs_list="$work/jobs"
: >"$jobs_list"
mkdir -p "$work/inflight"

# `"targets"` of every modules/ manifest, read once: <cell>\t<targets, space-
# separated>. A manifest without the field has no line; one node cannot read,
# or whose `targets` is not an array of strings, has `!` for its list.
node -e '
  const fs = require("fs"), path = require("path");
  const root = process.argv[1];
  let dirs = [];
  try { dirs = fs.readdirSync(path.join(root, "modules")).sort(); } catch {}
  for (const d of dirs) {
    const file = path.join(root, "modules", d, "botopink.json");
    if (!fs.existsSync(file)) continue;
    let m;
    try { m = JSON.parse(fs.readFileSync(file, "utf8")); } catch { console.log(`modules/${d}\t!`); continue; }
    if (m.targets === undefined) continue;
    const ok = Array.isArray(m.targets) && m.targets.every((t) => typeof t === "string" && /^[A-Za-z]+$/.test(t));
    console.log(`modules/${d}\t${ok ? m.targets.join(" ") : "!"}`);
  }' "$here" >"$work/manifest-targets"

# Schedule <cell> of <kind targets…> under the narrowing <declared…> written in
# <by>: a run job on each target of the run the cell keeps, an audit job on each
# one it excludes — or one `*` failure when the narrowing itself is malformed.
narrowed() { # <path> <by> <kind targets> <declared>
    local f="$1" by="$2" kind="$3" declared="$4" t d seen="" why=""
    for d in $declared; do
        case " $ALL_TARGETS " in *" $d "*) ;; *) why="names \`$d\`, which is no target (one of: $ALL_TARGETS)"; break ;; esac
        case " $kind " in *" $d "*) ;; *) why="names $d, a target this kind of cell never runs on (its targets: $kind)"; break ;; esac
        case " $seen " in *" $d "*) why="names $d twice"; break ;; esac
        seen="$seen $d"
    done
    if [ -z "$why" ]; then
        [ -n "$seen" ] || why="names no target"
        local missing=0
        for t in $kind; do case " $seen " in *" $t "*) ;; *) missing=1 ;; esac; done
        [ -n "$why" ] || [ $missing -eq 1 ] || why="names every target the cell runs on, so it narrows nothing: delete it"
    fi
    if [ -n "$why" ]; then
        printf '*\t%s\tfail\t%s\n' "$f" "$by $why" >"$work/r-narrowing-$(printf '%s' "$f" | tr '/.' '__')"
        return
    fi
    for t in "${targets[@]}"; do
        case " $kind " in *" $t "*) ;; *) continue ;; esac
        case " $seen " in
            *" $t "*) printf '%s\t%s\trun\n' "$f" "$t" >>"$jobs_list" ;;
            *) printf '%s\t%s\taudit:%s\n' "$f" "$t" "$by" >>"$jobs_list" ;;
        esac
    done
}

for f in "${files[@]}"; do
    f="${f%/}"
    if [ ! -f "$here/$f" ] && [ ! -d "$here/$f" ]; then
        echo "run.sh: no such cell: $f" >&2; exit 2
    fi
    case "$f" in
        reject/*) printf '%s\t*\trun\n' "$f" >>"$jobs_list" ;;
        # `botopink test` refuses wasm, so a test/ cell never runs there (see
        # AGENTS.md § the targets).
        test/*) for t in "${targets[@]}"; do
                    [ "$t" = "wasm" ] && continue
                    printf '%s\t%s\trun\n' "$f" "$t" >>"$jobs_list"
                done ;;
        run/*)  if [ -f "$here/${f%.bp}.targets" ]; then
                    narrowed "$f" "${f%.bp}.targets" "$ALL_TARGETS" "$(tr -s '[:space:]' ' ' <"$here/${f%.bp}.targets")"
                else
                    for t in "${targets[@]}"; do printf '%s\t%s\trun\n' "$f" "$t" >>"$jobs_list"; done
                fi ;;
        modules/*)
                # a project cell of the test/ kind (a `test/` tree, no
                # expected.out) is `botopink test`: commonJS, erlang and beam
                kind="$ALL_TARGETS"
                if [ -d "$here/$f/test" ] && [ ! -f "$here/$f/expected.out" ]; then kind="commonJS erlang beam"; fi
                declared="$(awk -F '\t' -v c="$f" '$1 == c { print $2 }' "$work/manifest-targets")"
                if [ "$declared" = "!" ]; then
                    printf '*\t%s\tfail\t%s\n' "$f" "$f/botopink.json is not JSON, or its \"targets\" is not an array of target names" >"$work/r-narrowing-$(printf '%s' "$f" | tr '/.' '__')"
                elif [ -n "$declared" ]; then
                    narrowed "$f" "$f/botopink.json \"targets\"" "$kind" "$declared"
                else
                    for t in "${targets[@]}"; do
                        case " $kind " in *" $t "*) printf '%s\t%s\trun\n' "$f" "$t" >>"$jobs_list" ;; esac
                    done
                fi ;;
        *) for t in "${targets[@]}"; do printf '%s\t%s\trun\n' "$f" "$t" >>"$jobs_list"; done ;;
    esac
done
# `--list`: the plan is the answer — one line per job, nothing spawned.
if [ $list -eq 1 ]; then
    while IFS=$'\t' read -r f t what; do printf '%s\t%s\t%s\n' "$f" "$t" "${what%%:*}"; done <"$jobs_list"
    exit 0
fi

# ── § the result store ────────────────────────────────────────────────────────
# Decisions 229 and 249 (front 00-gate/133-gate-speed): a job whose key equals
# the key of a stored PASS is answered from the store — its verdict file is the
# stored one, byte for byte — and every other job runs. The key is the SHA-256
# of every byte the job reads (scripts/lib/result-store.js): the compiler's
# build configuration and its sources partitioned by backend (the shared ones
# and the job's target's own, every target's for a `reject/` job), this
# script, pool.sh and result-store.js, the toolchain (node, the OTP release,
# wasmtime, the environment a compiler or runtime reads), every file of the
# library root (`--lib-root`, where `from "std"` resolves), and the cell's own
# files — `test/<n>.bp`; every `run/<n>.*` / `reject/<n>.*` file (source,
# `.out`, `.exit`, `.<t>.stderr`, `.<t>.expect`, `.targets`); the whole `modules/<n>/` tree —
# with the target and the job's kind. No analysis decides what a change can
# affect: a key that differs in one byte runs the job. Only a verdict whose
# every line is `ok` (or an audited exclusion) is written, and only when the
# job's key is the same after the run as before it (nothing moved under it). A
# cell whose inputs cannot be enumerated with certainty is never stored, and the
# report says why (result-store.js: a symbolic link, a dependency that leaves
# the cell, a library root above the scratch directory). The store lives in
# `<repo>/.botopinkbuild/cache/results/language/` (decision 225): deleting
# `.botopinkbuild/` wipes it; `--cold` never reads it and writes its passes
# (decision 249), so the warm run after a landing answers from them.
store_js="$repo/scripts/lib/result-store.js"
[ -n "$store_dir" ] || store_dir="$repo/.botopinkbuild/cache/results/language"
# One line per job: <verdict file>\t<path>\t<target>\t<what>, in plan order.
jobs_ids="$work/jobs-ids"
: >"$jobs_ids"
while IFS=$'\t' read -r f t what; do
    arg="$t"; [ "$t" = "*" ] && arg="${targets[0]}"
    s="$f-$arg"; s="${s//\//_}"; s="${s//./_}"
    case "$what" in audit:*) id="r-audit-$s" ;; *) id="r-$s" ;; esac
    printf '%s\t%s\t%s\t%s\n' "$id" "$f" "$t" "$what" >>"$jobs_ids"
done <"$jobs_list"
store_hits="$work/store-hits"
: >"$store_hits"
store_keys() { # <out> — the key of every job, from the files as they are now
    node "$store_js" keys --spec "$work/store-spec" --out "$1" --base "$here" \
        --compiler "$compiler" --global-file "run.sh=$runner" \
        --global-file "pool.sh=$repo/scripts/lib/pool.sh" --global-file "result-store.js=$store_js" \
        --global-tree "lib-root=$lib_root" --global-text "tests/language" --scratch "$work"
}
while IFS=$'\t' read -r id f t what; do
    case "$f" in
        modules/*) inputs="$f" ;;
        *) inputs=""
           for g in "$here/${f%.bp}".*; do [ -f "$g" ] && inputs="$inputs	${g#"$here/"}"; done
           inputs="${inputs#	}" ;;
    esac
    printf '%s\t%s %s\t%s\n' "$id" "$t" "$what" "$inputs"
done <"$jobs_ids" >"$work/store-spec"
store_keys "$work/keys-before" || { echo "run.sh: the result store's keys could not be computed" >&2; exit 2; }
if [ $cold -eq 0 ]; then
    node "$store_js" lookup --store "$store_dir" --keys "$work/keys-before" --work "$work" --out "$store_hits" ||
        { echo "run.sh: the result store could not be read" >&2; exit 2; }
fi

awk -F '\t' 'FILENAME == ARGV[1] { hit[$0] = 1; next } !($1 in hit)' "$store_hits" "$jobs_ids" |
while IFS=$'\t' read -r id f t what; do
    case "$what" in
        audit:*) printf 'audit_one\0%s\0%s\0%s\0' "$f" "$t" "${what#audit:}" ;;
        # The 4th field is `-`, never empty: BSD xargs (macOS) drops an empty
        # argument even under -0, and every later group of 4 would shift.
        *) if [ "$t" = "*" ]; then printf 'run_one\0%s\0%s\0-\0' "$f" "${targets[0]}"; else printf 'run_one\0%s\0%s\0-\0' "$f" "$t"; fi ;;
    esac
done | xargs -0 -r -n 4 -P "$jobs" bash -c 'pool_job "$work/inflight" "$0" "$1" "$2" "$3"'

store_total="$(grep -c . "$jobs_ids")"
store_from="$(grep -c . "$store_hits")"
store_note=""
[ $cold -eq 0 ] || store_note=" (--cold: nothing read from the store)"
store_keys "$work/keys-after" || { echo "run.sh: the result store's keys could not be computed" >&2; exit 2; }
read -r store_written store_moved < <(node "$store_js" save --store "$store_dir" --before "$work/keys-before" \
    --after "$work/keys-after" --work "$work" --hits "$store_hits" --pass lines-ok) ||
    { echo "run.sh: the result store could not be written" >&2; exit 2; }
[ "${store_moved:-0}" -eq 0 ] || store_note="$store_note ($store_moved not written: their inputs moved during the run)"
# Every job that can never be answered from the store, by reason.
: >"$work/store-never"
awk -F '\t' '
    $2 == "-" { if (!($3 in n)) order[++k] = $3; n[$3]++ }
    END { for (i = 1; i <= k; i++) printf "result store: %d job%s never stored — %s\n", n[order[i]], (n[order[i]] == 1 ? "" : "s"), order[i] }
' "$work/keys-before" >"$work/store-never"

cat "$work"/r-* 2>/dev/null | sort >"$work/results"
# How many jobs wrote their verdict — every job writes exactly one file
# (`r-<slug>`, `r-audit-<slug>`); a malformed narrowing writes `r-narrowing-*`
# without a job. `scripts/gate.sh` compares the count with `--list`.
jobs_audit="$(ls "$work" | grep -c '^r-audit-')"
jobs_ran="$(( $(ls "$work" | grep '^r-' | grep -vc '^r-narrowing-') ))"

# ── report ────────────────────────────────────────────────────────────────────
node - "$work/results" "$jobs_ran" "$jobs_audit" "$store_total" "$store_from" "$store_note" "$work/store-never" <<'EOF'
const fs = require("fs");
const [resultsPath, jobsRan, jobsAudit, storeTotal, storeFrom, storeNote, storeNever] = process.argv.slice(2);
const RED = "\x1b[0;31m", GREEN = "\x1b[0;32m", NC = "\x1b[0m";

// <target>\t<key>\t<ok|fail|audit>\t<detail>, sorted. An `audit` line is an
// exclusion the compiler backs with a host-binding refusal: not a cell that
// ran, so not in the `passed` count.
// The per-target line is what a claim of the form "every cell of X has a beam
// result" quotes; `*` is reject/ (one `botopink check`, no target) and a
// malformed narrowing (refused before any target ran).
let fails = 0, oks = 0, audited = 0;
const out = [];
const byTarget = new Map();
const tally = (t, k) => {
  if (!byTarget.has(t)) byTarget.set(t, { ok: 0, fail: 0 });
  byTarget.get(t)[k]++;
};
for (const line of fs.readFileSync(resultsPath, "utf8").split("\n")) {
  if (!line) continue;
  const [t, key, status, detail] = line.split("\t");
  if (status === "ok") { oks++; tally(t, "ok"); continue; }
  if (status === "audit") { audited++; continue; }
  out.push(`${RED}FAIL${NC}     [${t}] ${key} — ${detail || ""}`);
  fails++;
  tally(t, "fail");
}
for (const l of out) console.log(l);
if (audited) console.log(`narrowings: ${audited} exclusion${audited === 1 ? "" : "s"} audited — each stands on a host binding the target does not have`);
const order = ["commonJS", "erlang", "wasm", "beam", "*"];
const keys = [...byTarget.keys()].sort((a, b) => order.indexOf(a) - order.indexOf(b));
if (keys.length) console.log(`by target: ${keys.map((t) => `${t} ${byTarget.get(t).ok}/${byTarget.get(t).ok + byTarget.get(t).fail}`).join(" · ")}`);
console.log(`cells: ${jobsRan} jobs — ${jobsRan - jobsAudit} run, ${jobsAudit} audits`);
// § the result store: what was executed and what was answered from a stored
// pass; `scripts/gate.sh` holds run + from store to the plan.
process.stdout.write(fs.readFileSync(storeNever, "utf8"));
console.log(`result store: ${storeTotal} jobs — ${storeTotal - storeFrom} run, ${storeFrom} from store${storeNote}`);
const colour = fails ? RED : GREEN;
console.log(`\n${colour}language tests: ${oks} passed, ${fails} failed${NC}`);
process.exit(fails ? 1 : 0);
EOF
