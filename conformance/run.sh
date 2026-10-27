#!/usr/bin/env bash
# run.sh — botopink-lang's conformance suite (decisions 457, 466, 989, 990 (6)):
# the root package `modules/` — every self-checking module, loaded and run in one
# program — built once into its `.bpr` set and run on each target, every `test/`
# suite run by `botopink test --json`, and every library and workspace member of
# the checkout tested in process, one program per package per target (decisions
# 993, 995, 996, 1004) (`zig build test-conformance`, the gate's conformance
# stage).
#
# Usage:
#   conformance/run.sh [--target commonJS|erlang|wasm|beam|all|<t>,<t>…]
#                      [--compiler <botopink>]
#                      [--lib-root <dir>] [--only <path>] [--jobs <n>] [--list]
#   conformance/run.sh --self-test [--compiler <botopink>] [--lib-root <dir>]
#
#   --target    the targets the root package and the `test/` suites run on;
#               default `all`. A missing runtime fails the run; it never drops
#               a target (decision 67).
#   --compiler  the `botopink` binary; default <repo>/zig-out/bin/botopink
#   --lib-root  where `from "std"` resolves; default <compiler>/../../libs
#   --only      run the root package, the libraries or one suite (modules,
#               libraries, test/case_arms.bp, test/pub_val_in_a_test); may repeat. One module alone runs by
#               its own path: `cd modules/<m> && botopink run --target <t>`
#   --jobs      parallel jobs; default one per CPU, bounded by memory
#               (MemAvailable / 768 MiB) — § parallel jobs below
#   --list      print the plan and run nothing: one `<path>\t<target>\t<run|audit>`
#               line per job (the root package's path is `modules`, a library's
#               `libraries/<name>`). A whole run ends with
#               `cells: <J> jobs — <R> run, <A> audits`, and `scripts/gate.sh`
#               holds J to the number of lines `--list` prints: a run cannot
#               do fewer jobs than the tree declares
#   --suite     the directory holding modules/ and test/; default this
#               script's own. `--self-test` is its one caller.
#   --self-test prove § the targets of a test suite against synthetic suites:
#               a narrowing the compiler does not back fails the run, one it
#               backs schedules the suite on the declared targets alone. A
#               whole run of the suite (no --only) starts with it. (A loaded
#               package's narrowing is the compiler's audit at `emit`, decision
#               989 (3): `load-excluded-target-compiles`.)
#   --lib-timeout <s>
#               the wall-clock bound of one library's program on one target
#               (default 900 s); a run past it is that pair's red. `--self-test`
#               lowers it to show a hang caught; it never skips a pair
#   --cold      each `botopink` the run spawns gets `--cold` — the code cache of the
#               dependencies is not read (decision 509 (5)); `scripts/gate.sh
#               --cold` passes it
#
# Three kinds, every job in its own scratch directory:
#   modules/           the root package (decisions 989, 990 (6)): `modules/botopink.json`
#                      and `modules/src/main.bp`, one `runModule("<m>")` line per
#                      self-checking module — `modules/<m>/` or
#                      `modules/decisions-taken/<d>/` holding `botopink.json`,
#                      `src/main.bp` (its cases loaded from `cases/<case>/` at build,
#                      run, compared with `snapshot/main.snap`) and `snapshot/main.snap`.
#                      A bare `botopink build` writes its `.bpr` set once
#                      (§ the root package); a job per target runs the package there
#                      (`botopink run --target <t>`, reusing the set), and its printed verdicts —
#                      `ok   <m>` or `FAIL <m> — …` and the lines under it, then
#                      `modules: N checked — P passed, F failed` — are that target's
#                      result per module. The report adds `target runs: <t> built N,
#                      reused M` per target (decision 1008 (6)): the runs (the root
#                      package's, each library's) that emitted and compiled, and those
#                      whose target key matched; the CLI prints one `botopink-target:`
#                      stderr line under `BOTOPINK_TARGET_REPORT`, which run.sh hides.
#                      The list is held to the tree: a module on
#                      disk without its line, a line without its module, and a
#                      directory still in the old cell shape (`run/`, `refused/`,
#                      `cells/` with no `snapshot/main.snap`) are reds of their own; a
#                      front-166 draft (`docs.md` and `draft/` alone) is no module
#                      until promoted (decision 1002 (a)).
#   test/<name>.bp     `test "…" { … assert … }` blocks: `botopink test --target
#                      <t> --json` in a scratch project; every test must pass
#   test/<name>/       a whole project with a `test/` tree: `botopink test
#                      --target <t> --json`, keyed <name>::<test>. `"targets"`
#                      in its botopink.json narrows it, audited — § the targets
#                      of a test suite
#   libraries/<name>   every package `botopink packages --list` prints (decisions
#                      993, 995, 996, 1004): one program per package per target,
#                      its own process on the pool, loading the package by name
#                      and running its tests (``m.`test`()``) — § the libraries;
#                      the run also holds the workspace documents that quote the member list
#                      to the tool (`botopink packages --check-docs`, decision 993 (7))
#
# Outcome rules: a job passes or it fails, and a run fails on any `FAIL`. There
# is no list of known failures (decision 154): a red module is red until the
# compiler passes it.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(cd "$here/.." && pwd)"

target="all"
compiler="$repo/zig-out/bin/botopink"
lib_root=""
jobs=""
only=()
suite=""
self_test=0
cold=0
list=0
lib_timeout=900
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
        --lib-timeout) lib_timeout="$2"; shift 2 ;;
        --lib-timeout=*) lib_timeout="${1#*=}"; shift ;;
        -h|--help) sed -n '2,/^set -uo pipefail/p' "$0" | sed '$d'; exit 0 ;;
        *) echo "run.sh: unknown argument '$1'" >&2; exit 2 ;;
    esac
done
# `--cold` handed on to every `botopink build` / `test` / `run` (decision 509 (5)). A scalar, not an array:
# `export` carries no array into the exported job functions (decision 1006 P0), and the flag has no space.
cold_flag=""
[ "$cold" -eq 0 ] || cold_flag="--cold"
runner="$here/$(basename "${BASH_SOURCE[0]}")"
# The suite is read from `$here`; `--suite` points it at another tree.
whole_suite=0
if [ -n "$suite" ]; then
    [ -d "$suite" ] || { echo "run.sh: --suite is not a directory: $suite" >&2; exit 2; }
    here="$(cd "$suite" && pwd)"
elif [ ${#only[@]} -eq 0 ] && [ $self_test -eq 0 ] && [ $list -eq 0 ]; then
    whole_suite=1
fi

# ── § parallel jobs ──────────────────────────────────────────────────────────
# Every job is its own scratch directory and writes its verdict to its own
# `$work/r-<slug>` file; nothing is printed while jobs run, and the verdicts are
# sorted before they are reported. So how many jobs run at once changes the wall
# clock and nothing else: `--jobs 1` and the default print the same bytes and
# exit with the same status.
#
# The pool is scripts/lib/pool.sh — the former library runner's rule: one job per
# CPU, bounded by `MemAvailable / 768 MiB`, and a job admitted only while the
# machine's runnable threads are at most the CPU count (other gates share it).
# The root package is built once before the pool starts (§ the root package);
# each target's run of the package (reusing its `.bpr` set) is one job of the plan.
# shellcheck source=../scripts/lib/pool.sh
. "$repo/scripts/lib/pool.sh"
[ -n "$jobs" ] || jobs="$(pool_default_jobs)"
pool_check_jobs "$jobs" run.sh

# ── § beam ────────────────────────────────────────────────────────────────────
# `botopink test --target beam` assembles every module of the run beside
# itself and runs each test module's runner with `erl -pa`, and `botopink test
# --target wasm` runs each test unit under wasmtime (decision 513), so `test/`
# suites run on all four targets. The root package runs on each of them with
# `botopink run --target <t>`, from its one `.bpr` set.
#
# `erlc` and `erl` are gate dependencies already, so beam costs no new tool; a
# machine without them fails the run below rather than run fewer targets and
# say "all".
#
# ── § the targets of a test suite ─────────────────────────────────────────────
# A `test/` suite runs on commonJS, erlang, wasm and beam unless a project suite
# NARROWS itself with `"targets"` in its `botopink.json`. A narrowing is a
# claim about the compiler, and the runner checks it on every run: for each
# target of the run the suite excludes, `botopink build --target <t>` in the
# project must REFUSE it on a host binding —
#
#     `f` has no implementation for the <t> backend   (commonJS: `node`)
#     std-unsupported-on-target: std/<m> has no `#[@External.<Target>]` for target '<t>'
#     `#[compiler.beamMemory(…)]` has no meaning on the <t> backend
#
# — the one reason a program structurally has no row on a target. A target the
# build accepts, or refuses for any other reason, fails the run naming the
# suite; so is a narrowing that names an unknown target, the same one
# twice, or every target (it narrows nothing: delete it). No flag, list or
# environment variable turns the audit off (decision 67); `--self-test` shows
# each refusal firing. A loaded package's narrowing is the compiler's own audit
# at `emit` (decision 989 (3)).
ALL_TARGETS="commonJS erlang wasm beam"
TEST_TARGETS="commonJS erlang wasm beam"
# `--target` takes `all`, one target, or a comma list (`wasm,beam`) — the subset the
# step gate runs (decision 460); a list is read in the canonical order, so the plan
# does not depend on how it was spelled.
case "$target" in
    all) targets=(commonJS erlang wasm beam) ;;
    *)
        targets=()
        IFS=',' read -r -a asked <<<"$target"
        for t in "${asked[@]}"; do
            case "$t" in commonJS|erlang|wasm|beam) ;; *)
                echo "run.sh: --target must be commonJS, erlang, wasm, beam, a comma list of them or all (got '$target')" >&2; exit 2 ;;
            esac
        done
        for t in $ALL_TARGETS; do
            for a in "${asked[@]}"; do [ "$a" = "$t" ] && { targets+=("$t"); break; }; done
        done
        [ "${#targets[@]}" -eq "${#asked[@]}" ] || { echo "run.sh: --target names a target twice (got '$target')" >&2; exit 2; }
        ;;
esac
# The tools of all four targets are needed whatever --target says: a run that
# lacks one fails rather than run fewer targets and say "all".
command -v erlc >/dev/null || { echo "run.sh: the beam target needs erlc" >&2; exit 2; }
command -v erl  >/dev/null || { echo "run.sh: the erlang and beam targets need erl" >&2; exit 2; }
command -v wasmtime >/dev/null || { echo "run.sh: the wasm target needs wasmtime" >&2; exit 2; }
[ -x "$compiler" ] || { echo "run.sh: compiler not found or not executable: $compiler" >&2; exit 2; }
compiler="$(cd "$(dirname "$compiler")" && pwd)/$(basename "$compiler")"
[ -n "$lib_root" ] || lib_root="$(cd "$(dirname "$compiler")/../.." && pwd)/libs"
command -v node >/dev/null || { echo "run.sh: node is required" >&2; exit 2; }

case "$lib_timeout" in ''|*[!0-9]*|0) echo "run.sh: --lib-timeout must be a positive count of seconds (got '$lib_timeout')" >&2; exit 2 ;; esac

work="$(mktemp -d "${TMPDIR:-/tmp}/bp-conformance.XXXXXX")"
# A library's program is written inside the checkout (§ the libraries), under a
# directory of this run's own, removed with the scratch.
lib_run=""
trap 'rm -rf "$work"; [ -z "$lib_run" ] || rm -rf "$lib_run"' EXIT

# ── § self-test ───────────────────────────────────────────────────────────────
# § the targets of a test suite, shown firing. A synthetic suite — two project
# suites whose narrowing the compiler backs with a host-binding refusal, one
# of each way a narrowing is refused, and a root package of a green and a red
# module beside a module still in the old cell shape and one with no line — is run
# through this script (`--suite`), and the report it prints must hold exactly
# these lines. A runner whose audit stopped refusing would print a green run
# over a narrowed suite; this is what reds instead.
self_test() {
    local st="$work/self-test" suite="$work/self-test/suite" missing=0 line
    mkdir -p "$suite/test" "$suite/modules"
    project_suite() { # <name> <"targets" JSON> — src/main.bp on stdin
        mkdir -p "$suite/test/$1/src" "$suite/test/$1/test"
        cat >"$suite/test/$1/src/main.bp"
        printf '{ "name": "%s", "version": "0.0.1", "src": "src/", "targets": %s }\n' "$1" "$2" >"$suite/test/$1/botopink.json"
        printf 'import {main.one};\n\ntest "one" {\n    assert one() == 1;\n}\n' >"$suite/test/$1/test/one_test.bp"
    }
    # Backed: the BEAM binds the function, commonJS refuses it.
    project_suite backed '["erlang", "beam"]' <<'BP'
import {compiler} from "std";

#[compiler.external(.Erlang("""1"""))]
declare fn host() -> i32;

pub fn one() -> i32 {
    return host();
}
BP
    # Unbacked: nothing about the program is a host's, and beam builds it.
    project_suite unbacked '["commonJS", "erlang"]' <<'BP'
pub fn one() -> i32 {
    return 1;
}
BP
    # Refused, but not on a host binding: no target compiles an unbound name.
    project_suite another_reason '["commonJS", "erlang"]' <<'BP'
pub fn one() -> i32 {
    return nowhere;
}
BP
    project_suite narrows_nothing '["commonJS", "erlang", "wasm", "beam"]' <<'BP'
pub fn one() -> i32 {
    return 1;
}
BP
    project_suite unknown_target '["commonJS", "jvm"]' <<'BP'
pub fn one() -> i32 {
    return 1;
}
BP
    # Decision 536: a single file declares no narrowing — a `// targets:` line in it is a comment, and
    # the file runs on every target.
    printf '// targets: commonJS\n\ntest "one" {\n    assert 1 == 1;\n}\n' >"$suite/test/comment_is_no_narrowing.bp"
    # The root package over two modules — `green`'s `main` answers `Ok`, `red`'s an `Error` —, the
    # real root program with its `runModule` lines replaced; `unlisted` has no line, and `oldshape`
    # is still a directory of cells: each a red of its own.
    mkdir -p "$suite/modules/src"
    printf '{ "name": "conformance", "version": "0.0.1" }\n' >"$suite/modules/botopink.json"
    awk '/^comptime \{$/ { print; print "    runModule(\"green\");"; print "    runModule(\"red\");"; print "    runModule(\"leftover\");"; print "    runModule(\"coverage\");"; skip = 1; next }
         skip && /^\}$/ { skip = 0 } !skip' "$here/modules/src/main.bp" >"$suite/modules/src/main.bp"
    for c in green red unlisted leftover coverage; do
        mkdir -p "$suite/modules/$c/src" "$suite/modules/$c/snapshot"
        printf '{ "name": "%s", "version": "0.0.1" }\n' "$c" >"$suite/modules/$c/botopink.json"
        printf 'botopink-cell 2\n' >"$suite/modules/$c/snapshot/main.snap"
    done
    # A module's `main` is `async` (decision 989 (9)).
    printf 'pub async fn main() -> Async<Result<void, string>> {\n    return;\n}\n' >"$suite/modules/green/src/main.bp"
    printf 'pub async fn main() -> Async<Result<void, string>> {\n    throw "1 red";\n}\n' >"$suite/modules/red/src/main.bp"
    cp "$suite/modules/green/src/main.bp" "$suite/modules/unlisted/src/main.bp"
    # Leftover cases (decisions 67, 989): `leftover` names `cells/covered` in a runCase and not `cells/uncovered`.
    printf 'fn runCase(comptime name: string) -> void {}\n\npub async fn main() -> Async<Result<void, string>> {\n    runCase("cells/covered");\n    return;\n}\n' >"$suite/modules/leftover/src/main.bp"
    mkdir -p "$suite/modules/leftover/cells/covered" "$suite/modules/leftover/cells/uncovered"
    printf '%s\n' '# the frozen list (decision 1011)' 'leftover cells/uncovered' >"$suite/leftover-cases.txt"
    # Decision 1011 (1): `cases/idle` is never run, and `runCase("ghost")` has no directory.
    printf 'fn runCase(comptime name: string) -> void {}\n\npub async fn main() -> Async<Result<void, string>> {\n    runCase("ran");\n    runCase("ghost");\n    return;\n}\n' >"$suite/modules/coverage/src/main.bp"
    mkdir -p "$suite/modules/coverage/cases/ran" "$suite/modules/coverage/cases/idle"
    mkdir -p "$suite/modules/oldshape/run/src"
    # A front-166 draft (decision 1002 (a)): no module, never reported.
    mkdir -p "$suite/modules/decisions-taken/drafted-1/draft"
    printf 'A draft.\n' >"$suite/modules/decisions-taken/drafted-1/docs.md"
    printf 'pub fn main() -> void {}\n' >"$suite/modules/decisions-taken/drafted-1/draft/main.bp"

    bash "$runner" --suite "$suite" --target all --compiler "$compiler" --lib-root "$lib_root" --jobs "$jobs" \
        >"$st/raw.txt" 2>&1
    local code=$?
    strip <"$st/raw.txt" >"$st/report.txt"
    [ $code -eq 1 ] || { echo "self-test: the synthetic suite exited $code, expected 1" >&2; missing=1; }
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        grep -qF -- "$line" "$st/report.txt" || { echo "self-test: the report lacks: $line" >&2; missing=1; }
    done <<'WANT'
[wasm] test/unbacked — excluded by test/unbacked/botopink.json "targets", but `botopink build --target wasm` accepts the suite
[beam] test/unbacked — excluded by test/unbacked/botopink.json "targets", but `botopink build --target beam` accepts the suite
[wasm] test/another_reason — excluded by test/another_reason/botopink.json "targets", and wasm refuses it for another reason than a host binding
[beam] test/another_reason — excluded by test/another_reason/botopink.json "targets", and beam refuses it for another reason than a host binding
[*] test/narrows_nothing — test/narrows_nothing/botopink.json "targets" names every target the suite runs on, so it narrows nothing
[*] test/unknown_target — test/unknown_target/botopink.json "targets" names `jvm`, which is no target
[commonJS] modules/red — red
[erlang] modules/red — red
[wasm] modules/red — red
[beam] modules/red — red
    1 red
[*] modules/unlisted — a module with no `runModule("unlisted")` line in modules/src/main.bp
[*] modules/coverage — case `cases/idle` is on disk and its main never runs it: no `runCase("idle")` in src/main.bp, decision 1011
[*] modules/coverage — `runCase("ghost")` names a case with no directory (cases/ghost), decision 1011
1 cases outside 989's shape (shrink-only)
[*] modules/oldshape — not in decision 989's shape (no botopink.json, src/main.bp and snapshot/main.snap): 990 (6)'s conversion
narrowings: 2 exclusions audited
by target: commonJS 5/7 · erlang 6/8 · wasm 4/7 · beam 5/8 · * 0/6
conformance: 20 passed, 16 failed
WANT
    # The backed suite ran where it said and nowhere else, and the green module
    # passed: no line may name them.
    if grep -qE 'test/backed|modules/green|comment_is_no_narrowing|drafted-1' "$st/report.txt"; then
        echo "self-test: a narrowing that stands on a host binding, or a green module, was reported:" >&2
        grep -E 'test/backed|modules/green|drafted-1' "$st/report.txt" >&2
        missing=1
    fi
    # An abnormal end of `botopink test --json` is a red naming the suite and the target, whatever
    # tests printed before it: a stub compiler prints the shapes a wasm trap leaves behind.
    local fake="$st/fake-botopink" fsuite="$st/fake-suite" shape
    mkdir -p "$fsuite/test" "$fsuite/modules"
    printf 'test "a" {\n    assert true;\n}\n\ntest "b" {\n    assert true;\n}\n\ntest "c" {\n    assert true;\n}\n' >"$fsuite/test/trap_mid.bp"
    cat >"$fake" <<'FAKE'
#!/usr/bin/env bash
ok() { printf '{"event":"test","name":"%s","status":"ok"}\n' "$1"; }
case "$FAKE_SHAPE" in
    crash)   ok a; ok b; echo '{"event":"module_crashed","module":"trap_mid","exit":134}'; echo '{"event":"summary","passed":0,"failed":1}'; exit 1 ;;
    nosum)   ok a; ok b; exit 0 ;;
    fewer)   ok a; ok b; echo '{"event":"summary","passed":2,"failed":0}'; exit 0 ;;
    exit1)   ok a; ok b; ok c; echo '{"event":"summary","passed":3,"failed":0}'; exit 1 ;;
    clean)   ok a; ok b; ok c; echo '{"event":"summary","passed":3,"failed":0}'; exit 0 ;;
    argv)    printf '%s %s\n' "$1" "$*" >>"$FAKE_ARGV"
             if [ "$1" = run ]; then echo 'library: 1 cases — 1 passed, 0 failed'; exit 0; fi
             ok a; ok b; ok c; echo '{"event":"summary","passed":3,"failed":0}'; exit 0 ;;
esac
FAKE
    chmod +x "$fake"
    for shape in crash nosum fewer exit1 clean; do
        FAKE_SHAPE=$shape bash "$runner" --suite "$fsuite" --target commonJS --compiler "$fake" --lib-root "$lib_root" --jobs 1 \
            >"$st/fake-$shape.raw" 2>&1
        code=$?
        strip <"$st/fake-$shape.raw" >"$st/fake-$shape.txt"
        if [ "$shape" = clean ]; then
            [ $code -eq 0 ] || { echo "self-test: a clean stub run exited $code, expected 0" >&2; missing=1; }
        else
            [ $code -eq 1 ] || { echo "self-test: the stub run '$shape' exited $code, expected 1 (an abnormal end passed)" >&2; missing=1; }
            grep -qE '\[commonJS\] test/trap_mid.bp' "$st/fake-$shape.txt" \
                || { echo "self-test: the stub run '$shape' did not name the suite and the target:" >&2; sed 's/^/    /' "$st/fake-$shape.txt" >&2; missing=1; }
        fi
    done
    # Decision 1006 P0: `--cold` reaches the exported jobs. The stub records each argv; run.sh given `--cold`
    # hands it to every `botopink` a job spawns, and without it hands none.
    local cflag argv
    for cflag in "" "--cold"; do
        argv="$st/argv${cflag:+-cold}.txt"
        : >"$argv"
        FAKE_SHAPE=argv FAKE_ARGV="$argv" bash "$runner" --suite "$fsuite" --target commonJS --compiler "$fake" --lib-root "$lib_root" \
            --jobs 1 $cflag >"$st/argv-run.txt" 2>&1
        if [ ! -s "$argv" ]; then
            echo "self-test: the stub compiler was never run by a job (--cold check)" >&2; missing=1
        elif [ -n "$cflag" ] && grep -qvF -- ' --cold' "$argv"; then
            echo "self-test: run.sh --cold did not hand --cold to every job:" >&2; sed 's/^/    /' "$argv" >&2; missing=1
        elif [ -z "$cflag" ] && grep -qF -- '--cold' "$argv"; then
            echo "self-test: run.sh without --cold handed --cold to a job:" >&2; sed 's/^/    /' "$argv" >&2; missing=1
        fi
    done
    # The libraries (§ the libraries, decision 1004 (7)): a checkout of four packages — `good` answers, `hard`
    # fails its program's build, `hangs` never ends, `broken`'s manifest is refused (`not-a-package`) — each its
    # own process, so each is red alone and `good` answers; a disabled.txt line on a pair that passes, one
    # on a target that runs, and one on a pair that fails.
    local lsuite="$st/lib-suite" fixture="$here/self-test/library_check/repository"
    mkdir -p "$lsuite/libraries"
    cp "$here/libraries/botopink.json" "$lsuite/libraries/botopink.json"
    cp -R "$fixture" "$lsuite/repository"
    printf '%s\n' '# the self-test' 'good beam — decision 996' 'hard beam — decision 996' 'good commonJS — decision 996' >"$lsuite/disabled.txt"
    bash "$runner" --suite "$lsuite" --only libraries --target commonJS,beam --compiler "$compiler" --lib-root "$lib_root" \
        --jobs "$jobs" --lib-timeout 15 >"$st/lib-raw.txt" 2>&1
    code=$?
    strip <"$st/lib-raw.txt" >"$st/lib-report.txt"
    [ $code -eq 1 ] || { echo "self-test: the synthetic libraries exited $code, expected 1" >&2; missing=1; }
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        grep -qF -- "$line" "$st/lib-report.txt" || { echo "self-test: the libraries' report lacks: $line" >&2; missing=1; }
    done <<'WANT'
[commonJS] libraries/hard — the program ended without its summary
[commonJS] libraries/hangs — no answer within 15s (a hang): the run was stopped
[beam] libraries/hangs — no answer within 15s (a hang): the run was stopped
[commonJS] libraries/broken — not-a-package (botopink packages --list: repository/broken) — never loaded
[beam] libraries/broken — not-a-package (botopink packages --list: repository/broken) — never loaded
[beam] libraries/good — listed in conformance/disabled.txt, and it passes: delete its line (decision 996 (3))
[*] conformance/disabled.txt — line 4 switches off good on commonJS, a pair that runs
disabled [beam] libraries/hard
libraries: 8 package × target pairs — 1 ok, 0 no tests, 0 excluded, 6 failed, 1 disabled
2 disabled (shrink-only, decision 996)
cells: 8 jobs — 8 run, 0 audits
WANT
    if grep -qE 'FAIL .*\[commonJS\] libraries/good|FAIL .*\[beam\] libraries/hard' "$st/lib-report.txt"; then
        echo "self-test: a library that answers, or a disabled pair that fails, was reported red:" >&2
        grep -E 'libraries/good|libraries/hard' "$st/lib-report.txt" >&2
        missing=1
    fi
    if [ $missing -ne 0 ]; then
        echo "self-test: FAILED — the synthetic suite's report was:" >&2
        sed 's/^/    /' "$st/report.txt" >&2
        echo "self-test: the synthetic libraries' report was:" >&2
        sed 's/^/    /' "$st/lib-report.txt" >&2
        return 1
    fi
    echo "self-test: 4 malformed or unbacked narrowings refused, 1 backed one scheduled on its declared targets alone, a red module and two roster reds named, 4 abnormal ends of a run (a trap, no summary, fewer results, a bare non-zero exit) red; 4 libraries each answered alone (a build that fails, a hang, a refused manifest), 3 disabled.txt lines held to decision 996; --cold reaches a job only when given (decision 1006 P0)"
}

# ── collect the jobs' paths ───────────────────────────────────────────────────
# `modules` is the root package, one path (§ the root package); a module alone is
# run by its own path, outside this runner.
files=()
if [ ${#only[@]} -gt 0 ]; then
    for f in "${only[@]}"; do
        f="${f%/}"
        case "$f" in
            modules/*) echo "run.sh: --only takes the root package (modules), not one module: run $f by its path (cd $f && botopink run --target <t>)" >&2; exit 2 ;;
            libraries/*) echo "run.sh: --only takes the libraries whole (libraries), not one package: the plan is botopink packages --list's" >&2; exit 2 ;;
        esac
        files+=("$f")
    done
else
    while IFS= read -r f; do files+=("$f"); done < <(cd "$here" && { ls test/*.bp 2>/dev/null; ls -d test/*/ 2>/dev/null | sed 's:/$::'; } | sort)
    [ ! -f "$here/modules/botopink.json" ] || files+=(modules)
    [ ! -f "$here/libraries/botopink.json" ] || files+=(libraries)
fi

# ── one job → result lines in $work/results ──────────────────────────────────
#   <target>\t<key>\t<ok|fail>\t<detail>
# key is <path>::<test name> for a test suite, <path> otherwise; a suite that
# does not compile yields a single `<path>` line with status `fail`.
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
# Decision 1008 (6): `BOTOPINK_TARGET_REPORT` makes a `--target` run print one stderr line,
# `botopink-target: built|reused` (emitted and compiled, or its target key matched and it only
# executed). `note_target` moves it out of a run's stderr into `$work/bt-<target>-<slug>`, which the
# report counts as `built N, reused M` per target.
note_target() { # <target> <slug> <stderr file>
    local l
    l="$(sed -n 's/^botopink-target: //p' "$3" | tail -1)"
    [ -z "$l" ] || { printf '%s\n' "$l" >"$work/bt-$1-$2"; sed -i '/^botopink-target: /d' "$3"; }
}
# progress lines (`Checking 1 module(s)...`) carry no refusal
quiet() { strip | grep -vE '^[[:space:]]*(Checking|Checked|Compiling|Compiled) ' || true; }

project() { # <dir>
    mkdir -p "$1/src" "$1/test"
    printf '{ "name": "conformance_tests", "version": "0.0.1", "src": "src/" }\n' > "$1/botopink.json"
}

# `botopink test --json` in <dir>; one result line per test, keyed <path>::<name>,
# or one `fail` line for <path> when nothing ran.
test_project() { # <dir> <path> <target> <out>
    local dir="$1" path="$2" t="$3" out="$4" code
    (cd "$dir" && with_timeout 300 "$compiler" test --target "$t" --json $cold_flag >"$dir/o.json" 2>"$dir/e.txt")
    code=$?
    json_tests <"$dir/o.json" >"$dir/tests.tsv"
    if [ ! -s "$dir/tests.tsv" ]; then
        local why; why="$(strip <"$dir/e.txt" | grep -m1 -E 'error' | tr '\t' ' ')"
        if grep -q '"event":"module_crashed"' "$dir/o.json"; then
            why="the run ended abnormally ($(grep -m1 '"event":"module_crashed"' "$dir/o.json" | sed -n 's/.*"exit":\([0-9]*\).*/exit \1/p'))${why:+: $why}"
            printf '%s\t%s\t%s\t%s\n' "$t" "$path" fail "${why}" >"$out"
        else
            printf '%s\t%s\t%s\t%s\n' "$t" "$path" fail "does not compile: ${why:-no test ran}" >"$out"
        fi
    else
        : >"$out"
        while IFS=$'\t' read -r name status why; do
            printf '%s\t%s::%s\t%s\t%s\n' "$t" "$path" "$name" "$status" "$why" >>"$out"
        done <"$dir/tests.tsv"
        # A run that ended abnormally is a red of its own, whatever its printed tests said: a
        # `module_crashed` record (a wasm trap, a runner that died), a missing summary, a non-zero
        # exit with no failing test, fewer results than the suite declares.
        local ran declared problem=""
        ran="$(wc -l <"$dir/tests.tsv")"
        declared="$(cd "$dir" && { find src test -name '*.bp' 2>/dev/null | xargs -r cat; } | grep -cE '^[[:space:]]*test[[:space:]]+"')"
        if grep -q '"event":"module_crashed"' "$dir/o.json"; then problem="the run crashed after $ran of $declared tests (a trap, or a runner that died)"
        elif ! grep -q '"event":"summary"' "$dir/o.json"; then problem="the run printed no summary after $ran of $declared tests"
        elif [ "$ran" -lt "$declared" ]; then problem="$ran results for $declared declared tests"
        elif [ $code -ne 0 ] && ! grep -q "^[^$(printf '\t')]*$(printf '\t')fail" "$dir/tests.tsv"; then problem="botopink test exited $code with every test ok"
        fi
        [ -z "$problem" ] || printf '%s\t%s\t%s\t%s\n' "$t" "$path" fail "$problem" >>"$out"
    fi
}

# ── § the root package ────────────────────────────────────────────────────────
# `modules/` is one botopink package (decisions 989, 990 (6)): its `main` loads
# every self-checking module at build (`compiler.load`), runs each in turn and
# prints its verdicts. It is built ONCE, before the pool starts, by a bare
# `botopink build` in `modules/` — the package's `.bpr` set and its key under
# `modules/.botopinkbuild/runtime/conformance/`, target-independent (decisions
# 798, 1006 (2)) —, and each target's job is `botopink run --target <t>` there,
# which reuses that set while its key is fresh (1006 P3; `run` takes no `.bpr`
# path, 1009) — the comptime compile, the whole cost of the suite (m2-0063's
# ramp), is paid once for four targets, and not again on a later call while no
# file of the package changed.
# One process per target holds every module (989 (8)); a crash or a hang is that
# target's run red whole.
#
# The libraries are not lines of this program: one program per package per
# target beside it (§ the libraries, decision 1004 (1)).
root_built=0     # 1 when the bare build wrote (or found fresh) the package's `.bpr` set
root_refusal=""  # why the root package did not build

# The modules of the tree: every directory of `modules/` (and of
# `modules/decisions-taken/`) but the root's own `src/` and the build's dot
# directories, one `<path>` per line, sorted. A module is in decision 989's shape
# when it holds `botopink.json`, `src/main.bp` and `snapshot/main.snap`. A front-166
# draft — a directory holding `docs.md` and `draft/` and nothing else, no promoted
# program — is no module until it is promoted (decision 1002 (a)); `decision-cells.ts
# check` keeps its shape.
module_dirs() {
    (cd "$here/modules" && for d in */ decisions-taken/*/; do
        d="${d%/}"
        case "$d" in src|decisions-taken|'*'|'decisions-taken/*') continue ;; esac
        [ -d "$d" ] || continue
        draft_only "$d" && continue
        printf '%s\n' "$d"
    done) | LC_ALL=C sort
}
draft_only() { # <dir, relative to modules/>: `docs.md` and `draft/` alone
    local e has_draft=0
    for e in "$1"/*; do
        [ -e "$e" ] || continue
        case "${e##*/}" in
            docs.md) ;;
            draft) [ -d "$e" ] && has_draft=1 || return 1 ;;
            *) return 1 ;;
        esac
    done
    [ "$has_draft" -eq 1 ]
}
in_shape() { # <module path, relative to modules/>
    [ -f "$here/modules/$1/botopink.json" ] && [ -f "$here/modules/$1/src/main.bp" ] && [ -f "$here/modules/$1/snapshot/main.snap" ]
}
# The modules the root's `main.bp` runs: its `runModule("<path>")` lines, in order.
listed_modules() {
    sed -nE 's/^[[:space:]]*runModule\("([^"]+)"\);[[:space:]]*$/\1/p' "$here/modules/src/main.bp" 2>/dev/null
}

# The roster held to the tree: a red per module on disk not in 989's shape, per
# module in the shape with no line, per line naming no module in the shape.
# Each is a `*` result (`r-plan-*`, no job of the plan).
#
# Decision 1011: no case on disk goes unrun without a red. In a module in the shape,
# each `cases/<c>` needs a `runCase("<c>")` in its `src/main.bp`, and each literal
# `runCase("<x>")` needs its directory (`cases/<x>`, or the path from the module when
# it holds a `/`); a comment does not count. The cases still in a leftover `cells/`,
# `run/src/cases/` or `refused/src/cases/` are held to `conformance/leftover-cases.txt`,
# one `<module> <path from the module>` per line, frozen and shrink-only: a leftover
# case not on the list is red; a listed one that a `runCase("<path>")` now runs, or that
# is gone from the disk, is red until its line is deleted. The report prints
# `<N> cases outside 989's shape (shrink-only)`.
main_code() { grep -v '^[[:space:]]*//' "$here/modules/$1/src/main.bp"; } # <module>: its code, no comment lines
roster_red() { # <module> <slug> <detail>
    printf '*\tmodules/%s\tfail\t%s\n' "$1" "$3" >"$work/r-plan-$2"
}
roster_cases() { # <module>: decision 1011 (1) and (2) for one module in the shape
    local d="$1" m="$here/modules/$1" slug root c rel x code
    slug="$(printf '%s' "$d" | tr '/.' '__')"
    code="$(main_code "$d")"
    if [ -d "$m/cases" ]; then
        for c in "$m"/cases/*/; do
            [ -d "$c" ] || continue
            c="$(basename "$c")"
            printf '%s\n' "$code" | grep -qF -- "runCase(\"$c\")" \
                || roster_red "$d" "case-$slug-$c" "case \`cases/$c\` is on disk and its main never runs it: no \`runCase(\"$c\")\` in src/main.bp, decision 1011"
        done
    fi
    while IFS= read -r x; do
        [ -n "$x" ] || continue
        case "$x" in */*) rel="$x" ;; *) rel="cases/$x" ;; esac
        [ -d "$m/$rel" ] || roster_red "$d" "call-$slug-$(printf '%s' "$x" | tr '/.' '__')" "\`runCase(\"$x\")\` names a case with no directory ($rel), decision 1011"
    done < <(printf '%s\n' "$code" | sed -nE 's/.*runCase\("([^"]+)"\).*/\1/p' | sort -u)
    for root in cells run/src/cases refused/src/cases; do
        [ -d "$m/$root" ] || continue
        for c in "$m/$root"/*/; do
            [ -d "$c" ] || continue
            rel="$root/$(basename "$c")"
            printf '%s %s\n' "$d" "$rel" >>"$work/leftover-disk"
            if printf '%s\n' "$code" | grep -qF -- "runCase(\"$rel\")"; then
                grep -qxF -- "$d $rel" "$work/leftover-list" \
                    && roster_red "$d" "left-$slug-$(printf '%s' "$rel" | tr '/.' '__')" "\`$rel\` is now run by a runCase: delete its line from conformance/leftover-cases.txt (shrink-only, decision 1011)"
            elif grep -qxF -- "$d $rel" "$work/leftover-list"; then
                echo x >>"$work/leftover-count"
            else
                roster_red "$d" "left-$slug-$(printf '%s' "$rel" | tr '/.' '__')" "\`$rel\` is a case outside 989's shape and not on conformance/leftover-cases.txt: move it into cases/ and run it (decision 1011)"
            fi
        done
    done
}
roster() {
    local d slug listed="$work/root-listed" l n
    listed_modules >"$listed"
    : >"$work/leftover-disk"; : >"$work/leftover-count"
    grep -vE '^[[:space:]]*(#|$)' "$here/leftover-cases.txt" 2>/dev/null >"$work/leftover-list" || : >"$work/leftover-list"
    while IFS= read -r d; do
        slug="$(printf '%s' "$d" | tr '/.' '__')"
        if ! in_shape "$d"; then
            printf '*\tmodules/%s\tfail\t%s\n' "$d" "not in decision 989's shape (no botopink.json, src/main.bp and snapshot/main.snap): 990 (6)'s conversion" >"$work/r-plan-$slug"
        elif ! grep -qxF -- "$d" "$listed"; then
            printf '*\tmodules/%s\tfail\t%s\n' "$d" "a module with no \`runModule(\"$d\")\` line in modules/src/main.bp" >"$work/r-plan-$slug"
        fi
        if in_shape "$d"; then roster_cases "$d"; fi
    done < <(module_dirs)
    n=0
    while IFS= read -r l; do
        n=$((n + 1))
        grep -qxF -- "$l" "$work/leftover-disk" \
            || printf '*\tconformance/leftover-cases.txt\tfail\t%s\n' "\`$l\` is on the list and no longer a case on disk: delete its line (shrink-only, decision 1011)" >"$work/r-plan-stale-$n"
    done <"$work/leftover-list"
    while IFS= read -r d; do
        in_shape "$d" && continue
        slug="$(printf '%s' "$d" | tr '/.' '__')"
        [ -f "$work/r-plan-$slug" ] && continue
        printf '*\tmodules/%s\tfail\t%s\n' "$d" "modules/src/main.bp runs \`$d\`, which is no module in decision 989's shape" >"$work/r-plan-$slug"
    done <"$listed"
}

# Build the root package once — a bare `botopink build`, its `.bpr` set reused
# when fresh, rebuilt under `--cold` (decision 1006 (2), (4)): `root_built` 1, or
# `root_refusal` what the build printed (its first error lines).
build_root() {
    local dir="$work/root" code
    mkdir -p "$dir"
    export BOTOPINK_LIB_ROOTS="$lib_root"
    (cd "$here/modules" && with_timeout 7200 "$compiler" build $cold_flag >"$dir/o.txt" 2>"$dir/e.txt")
    code=$?
    if [ $code -eq 0 ]; then
        root_built=1
    else
        root_refusal="the root package does not build (botopink build: exit $code): $(strip <"$dir/e.txt" | grep -m3 -E 'error' | tr '\t\n' '  ')"
    fi
}

# One target's run of the root package: one result line per module the program
# printed a verdict for (`<t>\tmodules/<m>\tok|fail\t…`, a red module's lines under
# its verdict kept as its log), and a red of its own when the run ended without
# its summary or with fewer verdicts than lines.
run_root() { # <target> <out file>
    local t="$1" out="$2" dir="$work/root-$1" code
    mkdir -p "$dir"
    if [ "$ROOT_BUILT" != 1 ]; then
        printf '%s\t%s\t%s\t%s\n' "$t" modules fail "$ROOT_REFUSAL" >"$out"
        return
    fi
    # The set `build_root` wrote is fresh: this run emits from it, no comptime (1006 P3).
    # `--cold` reads no code cache and still reuses the fresh set (1006 (4)).
    (cd "$here/modules" && with_timeout 7200 "$compiler" run --target "$t" --out "$dir/out" $cold_flag >"$dir/o.txt" 2>"$dir/e.txt")
    code=$?
    note_target "$t" root "$dir/e.txt"
    strip <"$dir/o.txt" | T="$t" OUT="$out" LOGS="$work" EXPECT="$ROOT_LISTED" CODE="$code" ERR="$dir/e.txt" node -e '
      const fs = require("fs");
      const t = process.env.T, lines = fs.readFileSync(0, "utf8").split("\n");
      const rows = [], logs = new Map();
      let cur = null, summary = null;
      for (const l of lines) {
        let m;
        if ((m = /^ok   (\S+)$/.exec(l))) { rows.push([`modules/${m[1]}`, "ok", ""]); cur = null; }
        else if ((m = /^FAIL (\S+) — (.*)$/.exec(l))) { const k = `modules/${m[1]}`; rows.push([k, "fail", m[2]]); cur = k; logs.set(k, []); }
        else if ((m = /^modules: (\d+) checked/.exec(l))) { summary = Number(m[1]); cur = null; }
        else if (cur && l.startsWith("    ")) logs.get(cur).push(l.slice(4));
      }
      const slug = (k) => k.replace(/[/.]/g, "_");
      for (const [k, v] of logs) if (v.length) fs.writeFileSync(`${process.env.LOGS}/log-${t}-${slug(k)}`, v.join("\n") + "\n");
      const expect = Number(process.env.EXPECT);
      let problem = "";
      if (summary === null) {
        const err = fs.readFileSync(process.env.ERR, "utf8").split("\n").filter((l) => l.trim()).slice(-3).join(" ").replace(/\t/g, " ");
        problem = `the run ended without its summary after ${rows.length} of ${expect} modules (exit ${process.env.CODE})${err ? ": " + err : ""}`;
      } else if (summary !== rows.length || rows.length !== expect) problem = `${rows.length} verdicts and a summary of ${summary} for ${expect} modules`;
      let text = rows.map(([k, s, d]) => [t, k, s, d].join("\t") + "\n").join("");
      if (problem) text += [t, "modules", "fail", problem].join("\t") + "\n";
      fs.writeFileSync(process.env.OUT, text);
    '
}

# ── § the libraries ──────────────────────────────────────────────────────────
# Decisions 993, 995, 996, 1004: every package of the checkout — each library and
# workspace member `botopink packages --list` prints, run from `libraries/` — is
# tested in process: one program per package per target, its own process
# (`botopink run --target <t>`) on the pool, so a load that fails the build, a
# crash or a hang is that package's answer on that target alone (1004 (1)). The
# program is the package `libraries/` (its `botopink.json`) with a `src/main.bp`
# written on every run from the list, never committed: it loads the package by
# name (`compiler.load(package: …)`) and runs its tests (``m.`test`()``), one line
# per test and a summary. Each package × target is one job of the plan
# (`libraries/<name>`), its verdict one of
#   ok          every test passed
#   no tests    the package has none (it still loads and builds)
#   excluded    its `"targets"` excludes the target and the compiler proves it
#               (989 (3): `.Excluded`; an exclusion it does not prove refuses
#               the build, `load-excluded-target-compiles`, a red)
#   FAIL        a test failed, the load or the build refused, the run crashed,
#               ended without its summary or outlasted `--lib-timeout`;
#               `not-a-package` (packages --list) is given that verdict and
#               never loaded
#   disabled    the pair is listed in `disabled.txt` (decision 996) and failed
# and the plan's count is the list's: one job per listed name per target.
#
# `disabled.txt` (decision 996, a one-time exception to 67): the pairs that did
# not run when the libraries joined the suite (beam and wasm, which
# the former library runner never ran), one `<package> <target> — decision 996` line
# each. Shrink-only: a line on another target, a line twice, a malformed line or
# more lines than it was generated with (`DISABLED_GENERATED`) is a red; a listed
# pair that passes, or is now excluded, is a red until its line is deleted; a
# listed pair that fails is `disabled`, printed, and no red. Every run prints
# `N disabled (shrink-only, decision 996)`.
DISABLED_GENERATED=117 # the lines `disabled.txt` was generated with; it only goes down
DISABLED_TARGETS="beam wasm"
LIB_PROGRAM_TEMPLATE='import {compiler, compiler.Refused, compiler.RunFailure, compiler.TestReport, io.terminal.print} from "std";

//// Written by conformance/run.sh on every run (decisions 993 (2), 1004 (1)): the package
//// `@PACKAGE@`, loaded by name, its tests run in process on the target this program runs on;
//// `async { m.`test`() }` is one `Async` whether the tests await or not (989 (2)).

fn indent(text: string) -> string {
    var out: string[] = [];
    for (text.split("\n")) { l ->
        if (l != "") out.push("    " + l);
    }
    return out.join("\n");
}

fn report(answer: Result<TestReport, RunFailure>) -> void {
    case answer {
        Ok(r) {
            var red = 0;
            for r.cases { c ->
                if (c.ok) print("ok   " + c.name) else {
                    red = red + 1;
                    print("FAIL " + c.name + " — " + c.at + ": " + c.message);
                    if (c.output != "") print(indent(c.output));
                }
            }
            print("library: "
                + r.cases.length.toString()
                + " cases — "
                + (r.cases.length - red).toString()
                + " passed, "
                + red.toString()
                + " failed");
        }
        Error(f) {
            val kind = case f.kind {
                .Failed -> "failed";
                .Abort -> "aborted";
                .Refused -> "refused";
                .Excluded -> "excluded";
            };
            print("library: " + kind + " — " + f.message);
            if (f.output != "") print(indent(f.output));
        }
    }
}

fn refused(r: Refused) -> void {
    print("library: refused at build — "
        + r.diagnostics.length.toString()
        + " diagnostics");
    for (r.diagnostics) { d ->
        print("    "
            + d.file
            + ":"
            + d.line.toString()
            + ":"
            + d.column.toString()
            + ": "
            + d.message);
    }
}

comptime {
    val loaded = comptime compiler.load(package: "@PACKAGE@");
    case loaded {
        Ok(m) -> compiler.init({ ->
            val settled = async {
                val answer = async { m.`test`() };
                report(await answer);
            };
        });
        Error(r) -> compiler.init({ -> refused(r); });
    }
}

pub fn main() -> void {}
'

# The packages of the checkout: `<name>\t<dir>\t<targets>\t<kind>`, as
# `botopink packages --list` prints them from `libraries/` (its walk-up, not
# `--lib-root`'s: std is the checkout's `libs/std`).
libraries_list() {
    (cd "$here/libraries" && env -u BOTOPINK_LIB_ROOTS "$compiler" packages --list)
}

# One package on one target: its program written under the run's own directory
# inside `libraries/` (the name resolves by the checkout's walk-up), run as its
# own process under `--lib-timeout`, its printed lines turned into one verdict.
lib_one() { # <name> <target> <out file>
    local name="$1" t="$2" out="$3" key="libraries/$1" slug dir code kind dirs logf
    slug="$(printf '%s-%s' "$name" "$t" | tr '/.' '__')"
    logf="$work/log-$t-$(printf '%s' "$key" | tr '/.' '__')"
    kind="$(awk -F '\t' -v n="$name" '$1 == n { print $4 }' "$work/packages" | sort -u | tr '\n' ' ')"
    dirs="$(awk -F '\t' -v n="$name" '$1 == n { print $2 }' "$work/packages" | tr '\n' ' ')"
    local status detail
    if [ "$kind" != "package " ]; then
        status=fail
        detail="not-a-package (botopink packages --list: ${dirs% }) — never loaded"
    else
        dir="$LIB_RUN/$slug"
        mkdir -p "$dir/src"
        cp "$here/libraries/botopink.json" "$dir/botopink.json"
        printf '%s' "$LIB_PROGRAM_TEMPLATE" | sed "s/@PACKAGE@/$name/g" >"$dir/src/main.bp"
        (unset BOTOPINK_LIB_ROOTS; cd "$dir" && with_timeout "$LIB_TIMEOUT" "$compiler" run --target "$t" $cold_flag >"$dir/o.txt" 2>"$dir/e.txt")
        code=$?
        note_target "$t" "lib-$slug" "$dir/e.txt"
        strip <"$dir/o.txt" >"$dir/out.txt"
        local summary
        summary="$(grep -E '^library: ' "$dir/out.txt" | tail -1)"
        case "$summary" in
            "library: "*" cases — "*)
                local n f
                n="$(sed -nE 's/^library: ([0-9]+) cases.*/\1/p' <<<"$summary")"
                f="$(sed -nE 's/.* ([0-9]+) failed$/\1/p' <<<"$summary")"
                if [ "${f:-0}" -gt 0 ]; then
                    status=fail; detail="$f of $n tests failed"
                    grep -E '^FAIL |^    ' "$dir/out.txt" >"$logf"
                elif [ "${n:-0}" -eq 0 ]; then
                    status=notests; detail=""
                else
                    status=ok; detail=""
                fi
                if [ $code -ne 0 ] && [ "$status" != fail ]; then
                    status=fail; detail="botopink run exited $code after its summary"
                fi ;;
            "library: excluded — "*) status=excluded; detail="${summary#library: excluded — }" ;;
            "library: refused at build — "*)
                status=fail; detail="the load refused (${summary#library: refused at build — })"
                grep -E '^    ' "$dir/out.txt" >"$logf" ;;
            "library: "*)
                status=fail; detail="${summary#library: }"
                grep -E '^    ' "$dir/out.txt" >"$logf" ;;
            *)
                status=fail
                if [ $code -eq 124 ] || [ $code -eq 137 ]; then
                    detail="no answer within ${LIB_TIMEOUT}s (a hang): the run was stopped"
                else
                    detail="the program ended without its summary (botopink run exited $code): $(strip <"$dir/e.txt" | grep -m3 -E 'error' | tr '\t\n' '  ')"
                    strip <"$dir/e.txt" | grep -vE '^[[:space:]]*(Checking|Checked|Compiling|Compiled|wrote) ' | head -n 40 | sed 's/^/    /;s/^    //' >"$logf"
                fi ;;
        esac
        rm -rf "$dir"
    fi
    # Decision 996 (3): a listed pair that passes or is excluded leaves the list; one that fails is `disabled`.
    if grep -qxF -- "$name $t" "$work/disabled-pairs" 2>/dev/null; then
        case "$status" in
            ok|notests) status=fail; detail="listed in conformance/disabled.txt, and it passes: delete its line (decision 996 (3))"; rm -f "$logf" ;;
            excluded) status=fail; detail="listed in conformance/disabled.txt, and its \"targets\" excludes $t, proven: delete its line (decision 996 (3))" ;;
            fail) status=disabled; rm -f "$logf" ;;
        esac
    fi
    printf '%s\t%s\t%s\t%s\n' "$t" "$key" "$status" "$detail" >"$out"
}

# `disabled.txt` read and held to its rule (decision 996 (3)): its pairs in
# `$work/disabled-pairs` (`<package> <target>`), each line it breaks a `*` red.
read_disabled() {
    local f="$here/disabled.txt" n=0 line pkg tgt rest lineno=0
    : >"$work/disabled-pairs"
    [ -f "$f" ] || return 0
    while IFS= read -r line || [ -n "$line" ]; do
        lineno=$((lineno + 1))
        case "$line" in ''|'#'*) continue ;; esac
        read -r pkg tgt rest <<<"$line"
        if [ "$rest" != "— decision 996" ] || [ -z "$pkg" ]; then
            printf '*\tconformance/disabled.txt\tfail\t%s\n' "line $lineno is not \`<package> <target> — decision 996\`: $line" >"$work/r-plan-disabled-$lineno"
            continue
        fi
        case " $DISABLED_TARGETS " in
            *" $tgt "*) ;;
            *) printf '*\tconformance/disabled.txt\tfail\t%s\n' "line $lineno switches off $pkg on $tgt, a pair that runs (decision 996 (3): only the pairs that did not run when the list was generated)" >"$work/r-plan-disabled-$lineno"; continue ;;
        esac
        if grep -qxF -- "$pkg $tgt" "$work/disabled-pairs"; then
            printf '*\tconformance/disabled.txt\tfail\t%s\n' "line $lineno lists $pkg $tgt twice" >"$work/r-plan-disabled-$lineno"
            continue
        fi
        printf '%s %s\n' "$pkg" "$tgt" >>"$work/disabled-pairs"
        n=$((n + 1))
    done <"$f"
    if [ "$n" -gt "$DISABLED_GENERATED" ]; then
        printf '*\tconformance/disabled.txt\tfail\t%s\n' "$n lines, more than the $DISABLED_GENERATED it was generated with: the list only shrinks (decision 996 (3))" >"$work/r-plan-disabled-count"
    fi
    DISABLED_COUNT="$n"
}
DISABLED_COUNT=0

run_one() { # <path> <target>
    local path="$1" t="$2" slug dir out
    slug="$(printf '%s-%s' "$path" "$t" | tr '/.' '__')"
    dir="$work/p-$slug"; out="$work/r-$slug"
    rm -rf "$dir"
    export BOTOPINK_LIB_ROOTS="$lib_root"
    case "$path" in
        modules) run_root "$t" "$out" ;;
        libraries/*) lib_one "${path#libraries/}" "$t" "$out" ;;
        test/*.bp)
            project "$dir"
            cp "$here/$path" "$dir/test/$(basename "$path")"
            test_project "$dir" "$path" "$t" "$out" ;;
        test/*)
            cp -R "$here/$path" "$dir"
            test_project "$dir" "$path" "$t" "$out" ;;
        *) printf '*\t%s\t%s\t%s\n' "$path" fail "neither the root package (modules) nor under test/" >"$out" ;;
    esac
}
# One exclusion of a narrowed project suite, audited (§ the targets of a test
# suite): build it on the target it excludes and require a host-binding
# refusal. Result status `audit` on a refusal the narrowing may stand on, `fail`
# otherwise.
audit_one() { # <path> <excluded target> <the file that narrows>
    local path="$1" t="$2" by="$3" slug dir out
    slug="$(printf '%s-%s' "$path" "$t" | tr '/.' '__')"
    dir="$work/x-$slug"; out="$work/r-audit-$slug"
    rm -rf "$dir"
    export BOTOPINK_LIB_ROOTS="$lib_root"
    local code
    cp -R "$here/$path" "$dir"
    code=0
    # A suite with sources is built; one that is only test files (decision 536's narrowed single files)
    # has nothing to build. A host binding its test files carry shows when the tests are compiled for the target.
    if [ -n "$(find "$dir/src" -name '*.bp' 2>/dev/null | head -n 1)" ]; then
        (cd "$dir" && with_timeout 300 "$compiler" build --target "$t" $cold_flag >"$dir/o.txt" 2>"$dir/e.txt")
        code=$?
    else
        : >"$dir/o.txt"; : >"$dir/e.txt"
    fi
    if [ $code -eq 0 ]; then
        (cd "$dir" && with_timeout 300 "$compiler" test --target "$t" $cold_flag >"$dir/o.txt" 2>"$dir/e.txt")
        code=$?
    fi
    quiet <"$dir/o.txt" >"$dir/all.txt"; quiet <"$dir/e.txt" >>"$dir/all.txt"
    if [ $code -eq 0 ]; then
        printf '%s\t%s\t%s\t%s\n' "$t" "$path" fail "excluded by $by, but \`botopink build --target $t\` accepts the suite — a narrowing stands on a host-binding refusal: let it run on $t, and a red there is a row of that backend's front" >"$out"
    elif grep -qF -e 'has no implementation for the '"$t"' backend' -e 'has no implementation for the node backend' -e 'std-unsupported-on-target:' -e '`#[compiler.beamMemory(…)]` has no meaning on the '"$t"' backend' "$dir/all.txt"; then
        printf '%s\t%s\t%s\t\n' "$t" "$path" audit >"$out"
    else
        local first; first="$(grep -m1 -iE 'error' "$dir/all.txt" | tr '\t' ' ')"
        printf '%s\t%s\t%s\t%s\n' "$t" "$path" fail "excluded by $by, and $t refuses it for another reason than a host binding (got: ${first:-no error line}) — let the suite run there" >"$out"
    fi
}
export -f note_target run_one run_root lib_one test_project json_tests strip quiet project audit_one pool_job pool_admit pool_cpus with_timeout
export here work compiler lib_root LIB_PROGRAM_TEMPLATE cold_flag
export BOTOPINK_TARGET_REPORT=1
export LIB_TIMEOUT="$lib_timeout"

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

# `"targets"` of every project suite's manifest, read once: <suite>\t<targets,
# space-separated>. A manifest without the field has no line; one node cannot
# read, or whose `targets` is not an array of strings, has `!` for its list.
node -e '
  const fs = require("fs"), path = require("path");
  const root = process.argv[1];
  let dirs = [];
  try { dirs = fs.readdirSync(path.join(root, "test")).sort(); } catch {}
  for (const d of dirs) {
    const file = path.join(root, "test", d, "botopink.json");
    if (!fs.existsSync(file)) continue;
    let m;
    try { m = JSON.parse(fs.readFileSync(file, "utf8")); } catch { console.log(`test/${d}\t!`); continue; }
    if (m.targets === undefined) continue;
    const ok = Array.isArray(m.targets) && m.targets.every((t) => typeof t === "string" && /^[A-Za-z]+$/.test(t));
    console.log(`test/${d}\t${ok ? m.targets.join(" ") : "!"}`);
  }
' "$here" >"$work/manifest-targets"

# Schedule <suite> under the narrowing <declared…> written in <by>: a run job on
# each target of the run the suite keeps, an audit job on each one it excludes —
# or one `*` failure when the narrowing itself is malformed.
narrowed() { # <path> <by> <declared>
    local f="$1" by="$2" declared="$3" t d seen="" why=""
    for d in $declared; do
        case " $ALL_TARGETS " in *" $d "*) ;; *) why="names \`$d\`, which is no target"; break ;; esac
        case " $seen " in *" $d "*) why="names $d twice"; break ;; esac
        seen="$seen $d"
    done
    if [ -z "$why" ]; then
        [ -n "$seen" ] || why="names no target"
        local missing=0
        for t in $TEST_TARGETS; do case " $seen " in *" $t "*) ;; *) missing=1 ;; esac; done
        [ -n "$why" ] || [ $missing -eq 1 ] || why="names every target the suite runs on, so it narrows nothing: delete it"
    fi
    if [ -n "$why" ]; then
        printf '*\t%s\tfail\t%s\n' "$f" "$by $why" >"$work/r-narrowing-$(printf '%s' "$f" | tr '/.' '__')"
        return
    fi
    for t in "${targets[@]}"; do
        case " $TEST_TARGETS " in *" $t "*) ;; *) continue ;; esac
        case " $seen " in
            *" $t "*) printf '%s\t%s\trun\n' "$f" "$t" >>"$jobs_list" ;;
            *) printf '%s\t%s\taudit:%s\n' "$f" "$t" "$by" >>"$jobs_list" ;;
        esac
    done
}

for f in "${files[@]}"; do
    f="${f%/}"
    if [ ! -f "$here/$f" ] && [ ! -d "$here/$f" ]; then
        echo "run.sh: no such root package or suite: $f" >&2; exit 2
    fi
    case "$f" in
        # The root package: one job per target of the run, each a run of the package reusing its `.bpr` set.
        modules)
            for t in "${targets[@]}"; do printf '%s\t%s\trun\n' "$f" "$t" >>"$jobs_list"; done ;;
        # The libraries (§ the libraries): one job per package name `packages --list` prints, per target.
        libraries)
            libraries_list >"$work/packages" 2>"$work/packages.err" ||
                { echo "run.sh: botopink packages --list failed in $here/libraries:" >&2; cat "$work/packages.err" >&2; exit 2; }
            while IFS= read -r n; do
                for t in "${targets[@]}"; do printf 'libraries/%s\t%s\trun\n' "$n" "$t" >>"$jobs_list"; done
            done < <(cut -f1 "$work/packages" | LC_ALL=C sort -u) ;;
        test/*.bp|test/*)
            declared="$(awk -F '\t' -v c="$f" '$1 == c { print $2 }' "$work/manifest-targets")"
            # Only a project suite narrows (decision 536): its manifest's "targets"; a single file declares nothing.
            case "$f" in *.bp) narrow_by=""; narrow_bad="" ;; *) narrow_by="$f/botopink.json \"targets\""; narrow_bad="$f/botopink.json is not JSON, or its \"targets\" is not an array of target names" ;; esac
            if [ "$declared" = "!" ]; then
                printf '*\t%s\tfail\t%s\n' "$f" "$narrow_bad" >"$work/r-narrowing-$(printf '%s' "$f" | tr '/.' '__')"
            elif [ -n "$declared" ]; then
                narrowed "$f" "$narrow_by" "$declared"
            else
                for t in "${targets[@]}"; do
                    case " $TEST_TARGETS " in *" $t "*) printf '%s\t%s\trun\n' "$f" "$t" >>"$jobs_list" ;; esac
                done
            fi ;;
        *) echo "run.sh: not the root package, the libraries or a suite (modules, libraries, test/<name>.bp, test/<project>): $f" >&2; exit 2 ;;
    esac
done
# `--list`: the plan is the answer — one line per job, nothing spawned.
if [ $list -eq 1 ]; then
    while IFS=$'\t' read -r f t what; do printf '%s\t%s\t%s\n' "$f" "$t" "${what%%:*}"; done <"$jobs_list"
    exit 0
fi

# ── § run ─────────────────────────────────────────────────────────────────────
# Decision 510: every job runs on every run — no verdict is stored nor answered
# from a store. The jobs are the plan's lines, in plan order.
#
# The root package (§ the root package) is held to the tree and built once
# here, before the pool: its targets' jobs reuse its `.bpr` set.
ROOT_BUILT=0; ROOT_REFUSAL=""; ROOT_LISTED=0
if grep -q '^modules	' "$jobs_list"; then
    roster
    build_root
    ROOT_BUILT="$root_built"; ROOT_REFUSAL="$root_refusal"
    ROOT_LISTED="$(listed_modules | grep -c . || true)"
fi
export ROOT_BUILT ROOT_REFUSAL ROOT_LISTED
# The libraries' programs are written inside the checkout (the name resolves by its walk-up), under
# a directory of this run's own (§ the libraries); the disabled pairs are read once.
LIB_RUN=""
if grep -q '^libraries/' "$jobs_list"; then
    lib_run="$here/libraries/.run/$(basename "$work")"
    mkdir -p "$lib_run"
    LIB_RUN="$lib_run"
    # A workspace document that quotes the tool's member list is checked against the tool (decision 993 (7):
    # the former library runner's `doc_quotes`, now `botopink packages --check-docs`); a stale quote is a red of the plan.
    if ! docs_out="$(cd "$here/libraries" && env -u BOTOPINK_LIB_ROOTS "$compiler" packages --check-docs 2>&1)"; then
        printf '*\tbotopink packages --check-docs\tfail\t%s\n' "$(printf '%s' "$docs_out" | sed $'s/\x1b\\[[0-9;]*m//g' | tr '\n' ' ')" >"$work/r-plan-docs-quotes"
    fi
fi
read_disabled
export LIB_RUN
{
    while IFS=$'\t' read -r f t what; do
        case "$what" in
            audit:*) printf 'audit_one\0%s\0%s\0%s\0' "$f" "$t" "${what#audit:}" ;;
            # The 4th field is `-`, never empty: BSD xargs (macOS) drops an empty
            # argument even under -0, and every later group of 4 would shift.
            *) printf 'run_one\0%s\0%s\0-\0' "$f" "$t" ;;
        esac
    done <"$jobs_list"
} | xargs -0 -r -n 4 -P "$jobs" bash -c 'pool_job "$work/inflight" "$0" "$1" "$2" "$3"'

cat "$work"/r-* 2>/dev/null | sort >"$work/results"
# How many jobs wrote their verdict — every job writes exactly one file
# (`r-<slug>`, `r-audit-<slug>`); a malformed narrowing writes `r-narrowing-*`
# and the root package's roster `r-plan-*`, without a job. `scripts/gate.sh`
# compares the count with `--list`.
jobs_audit="$(ls "$work" | grep -c '^r-audit-' || true)"
jobs_ran="$(( $(ls "$work" | grep '^r-' | grep -vcE '^r-(narrowing|plan)-') ))"

# ── report ────────────────────────────────────────────────────────────────────
leftover_total=""
[ -f "$work/leftover-count" ] && leftover_total="$(grep -c . "$work/leftover-count" || true)"
node - "$work/results" "$jobs_ran" "$jobs_audit" "$work" "$DISABLED_COUNT" "$([ -f "$here/disabled.txt" ] && echo 1 || echo 0)" "$leftover_total" <<'EOF'
const fs = require("fs");
const [resultsPath, jobsRan, jobsAudit, work, disabledCount, hasDisabled, leftover] = process.argv.slice(2);
const RED = "\x1b[0;31m", GREEN = "\x1b[0;32m", NC = "\x1b[0m";

// <target>\t<key>\t<ok|fail|audit>\t<detail>, sorted. An `audit` line is an
// exclusion the compiler backs with a host-binding refusal: not a cell that
// ran, so not in the `passed` count.
// The per-target line is what a claim of the form "every suite of X has a beam
// result" quotes; `*` is a malformed narrowing (refused before any target ran)
// and a red of the root package's roster (a module the list and the tree do not
// agree on). A red module's FAIL line is followed by what the root program
// printed under its verdict: the module's red cases and their differences.
let fails = 0, oks = 0, audited = 0;
const out = [], disabled = [];
// The libraries' verdicts per target (decisions 993 (6), 996): ok, no tests, excluded, FAIL, disabled.
const libs = { ok: 0, notests: 0, excluded: 0, fail: 0, disabled: 0 };
const isLib = (k) => k.startsWith("libraries/");
const byTarget = new Map();
const tally = (t, k) => {
  if (!byTarget.has(t)) byTarget.set(t, { ok: 0, fail: 0 });
  byTarget.get(t)[k]++;
};
for (const line of fs.readFileSync(resultsPath, "utf8").split("\n")) {
  if (!line) continue;
  const [t, key, status, detail] = line.split("\t");
  if (isLib(key)) libs[status in libs ? status : "fail"]++;
  if (status === "ok" || status === "notests") { oks++; tally(t, "ok"); continue; }
  if (status === "audit") { audited++; continue; }
  if (status === "excluded") continue;
  if (status === "disabled") { disabled.push(`disabled [${t}] ${key}`); continue; }
  out.push(`${RED}FAIL${NC}     [${t}] ${key} — ${detail || ""}`);
  const log = `${work}/log-${t}-${key.replace(/[/.]/g, "_")}`;
  if (fs.existsSync(log)) {
    for (const l of fs.readFileSync(log, "utf8").replace(/\n$/, "").split("\n")) out.push(`    ${l}`);
  }
  fails++;
  tally(t, "fail");
}
for (const l of out) console.log(l);
if (audited) console.log(`narrowings: ${audited} exclusion${audited === 1 ? "" : "s"} audited — each stands on a host binding the target does not have`);
for (const l of disabled) console.log(l);
const libTotal = Object.values(libs).reduce((a, b) => a + b, 0);
if (libTotal) console.log(`libraries: ${libTotal} package × target pairs — ${libs.ok} ok, ${libs.notests} no tests, ${libs.excluded} excluded, ${libs.fail} failed, ${libs.disabled} disabled`);
if (hasDisabled === "1") console.log(`${disabledCount} disabled (shrink-only, decision 996)`);
const order = ["commonJS", "erlang", "wasm", "beam", "*"];
const keys = [...byTarget.keys()].sort((a, b) => order.indexOf(a) - order.indexOf(b));
if (keys.length) console.log(`by target: ${keys.map((t) => `${t} ${byTarget.get(t).ok}/${byTarget.get(t).ok + byTarget.get(t).fail}`).join(" · ")}`);
// Decision 1008 (6): per target, the runs that emitted and compiled (built) and the runs whose target key
// matched (reused) — the root package's and each library's, from the `botopink-target:` line of each run.
const bt = new Map();
for (const f of fs.readdirSync(work)) {
  const m = /^bt-([^-]+)-/.exec(f);
  if (!m) continue;
  if (!bt.has(m[1])) bt.set(m[1], { built: 0, reused: 0 });
  const v = fs.readFileSync(`${work}/${f}`, "utf8").trim();
  if (v in bt.get(m[1])) bt.get(m[1])[v]++;
}
const btKeys = [...bt.keys()].sort((a, b) => order.indexOf(a) - order.indexOf(b));
if (btKeys.length) console.log(`target runs: ${btKeys.map((t) => `${t} built ${bt.get(t).built}, reused ${bt.get(t).reused}`).join(" · ")}`);
if (leftover !== "") console.log(`${leftover} cases outside 989's shape (shrink-only)`);
console.log(`cells: ${jobsRan} jobs — ${jobsRan - jobsAudit} run, ${jobsAudit} audits`);
const colour = fails ? RED : GREEN;
console.log(`\n${colour}conformance: ${oks} passed, ${fails} failed${NC}`);
process.exit(fails ? 1 : 0);
EOF
