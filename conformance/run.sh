#!/usr/bin/env bash
# run.sh — botopink-lang's conformance suite (decisions 457, 466, 989, 990 (6)):
# the root package `modules/` — every self-checking module, loaded and run in one
# program — built once into one `.bpr` and run on each target, and every `test/`
# suite run by `botopink test --json` (`zig build test-conformance`, the gate's
# conformance stage).
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
#   --only      run the root package or one suite (modules, test/case_arms.bp,
#               test/pub_val_in_a_test); may repeat. One module alone runs by
#               its own path: `cd modules/<m> && botopink run --target <t>`
#   --jobs      parallel jobs; default one per CPU, bounded by memory
#               (MemAvailable / 768 MiB) — § parallel jobs below
#   --list      print the plan and run nothing: one `<path>\t<target>\t<run|audit>`
#               line per job (the root package's path is `modules`). A whole run ends with
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
#                      `botopink build --emit-runtime` writes its one `.bpr` once
#                      (§ the root package); a job per target runs it there
#                      (`botopink run --target <t> <bpr>`), and its printed verdicts —
#                      `ok   <m>` or `FAIL <m> — …` and the lines under it, then
#                      `modules: N checked — P passed, F failed` — are that target's
#                      result per module. The list is held to the tree: a module on
#                      disk without its line, a line without its module, and a
#                      directory still in the old cell shape (`run/`, `refused/`,
#                      `cells/` with no `snapshot/main.snap`) are reds of their own.
#   test/<name>.bp     `test "…" { … assert … }` blocks: `botopink test --target
#                      <t> --json` in a scratch project; every test must pass
#   test/<name>/       a whole project with a `test/` tree: `botopink test
#                      --target <t> --json`, keyed <name>::<test>. `"targets"`
#                      in its botopink.json narrows it, audited — § the targets
#                      of a test suite
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
        -h|--help) sed -n '2,66p' "$0"; exit 0 ;;
        *) echo "run.sh: unknown argument '$1'" >&2; exit 2 ;;
    esac
done
# `--cold` handed on to every `botopink build` / `test` (decision 509 (5)).
cold_flag=()
[ "$cold" -eq 0 ] || cold_flag=(--cold)
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
# The pool is scripts/lib/pool.sh — `botopink-lib-test`'s rule: one job per
# CPU, bounded by `MemAvailable / 768 MiB`, and a job admitted only while the
# machine's runnable threads are at most the CPU count (other gates share it).
# The root package is built once before the pool starts (§ the root package);
# each target's run of its `.bpr` is one job of the plan.
# shellcheck source=../scripts/lib/pool.sh
. "$repo/scripts/lib/pool.sh"
[ -n "$jobs" ] || jobs="$(pool_default_jobs)"
pool_check_jobs "$jobs" run.sh

# ── § beam ────────────────────────────────────────────────────────────────────
# `botopink test --target beam` assembles every module of the run beside
# itself and runs each test module's runner with `erl -pa`, and `botopink test
# --target wasm` runs each test unit under wasmtime (decision 513), so `test/`
# suites run on all four targets. The root package's `.bpr` runs on each of
# them with `botopink run --target <t>`.
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

work="$(mktemp -d "${TMPDIR:-/tmp}/bp-conformance.XXXXXX")"
trap 'rm -rf "$work"' EXIT

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
    awk '/^comptime \{$/ { print; print "    runModule(\"green\");"; print "    runModule(\"red\");"; skip = 1; next }
         skip && /^\}$/ { skip = 0 } !skip' "$here/modules/src/main.bp" >"$suite/modules/src/main.bp"
    for c in green red unlisted; do
        mkdir -p "$suite/modules/$c/src" "$suite/modules/$c/snapshot"
        printf '{ "name": "%s", "version": "0.0.1" }\n' "$c" >"$suite/modules/$c/botopink.json"
        printf 'botopink-cell 2\n' >"$suite/modules/$c/snapshot/main.snap"
    done
    # A module's `main` is `async` (decision 989 (9)).
    printf 'pub async fn main() -> Async<Result<void, string>> {\n    return;\n}\n' >"$suite/modules/green/src/main.bp"
    printf 'pub async fn main() -> Async<Result<void, string>> {\n    throw "1 red";\n}\n' >"$suite/modules/red/src/main.bp"
    cp "$suite/modules/green/src/main.bp" "$suite/modules/unlisted/src/main.bp"
    mkdir -p "$suite/modules/oldshape/run/src"

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
[*] modules/oldshape — not in decision 989's shape (no botopink.json, src/main.bp and snapshot/main.snap): 990 (6)'s conversion
narrowings: 2 exclusions audited
by target: commonJS 3/5 · erlang 4/6 · wasm 2/5 · beam 3/6 · * 0/4
conformance: 12 passed, 14 failed
WANT
    # The backed suite ran where it said and nowhere else, and the green module
    # passed: no line may name them.
    if grep -qE 'test/backed|modules/green|comment_is_no_narrowing' "$st/report.txt"; then
        echo "self-test: a narrowing that stands on a host binding, or a green module, was reported:" >&2
        grep -E 'test/backed|modules/green' "$st/report.txt" >&2
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
    if [ $missing -ne 0 ]; then
        echo "self-test: FAILED — the synthetic suite's report was:" >&2
        sed 's/^/    /' "$st/report.txt" >&2
        return 1
    fi
    echo "self-test: 4 malformed or unbacked narrowings refused, 1 backed one scheduled on its declared targets alone, a red module and two roster reds named, 4 abnormal ends of a run (a trap, no summary, fewer results, a bare non-zero exit) red"
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
        esac
        files+=("$f")
    done
else
    while IFS= read -r f; do files+=("$f"); done < <(cd "$here" && { ls test/*.bp 2>/dev/null; ls -d test/*/ 2>/dev/null | sed 's:/$::'; } | sort)
    [ ! -f "$here/modules/botopink.json" ] || files+=(modules)
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
    (cd "$dir" && with_timeout 300 "$compiler" test --target "$t" --json ${cold_flag[@]+"${cold_flag[@]}"} >"$dir/o.json" 2>"$dir/e.txt")
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
# prints its verdicts. It is built ONCE, before the pool starts, into one `.bpr`
# (`botopink build --emit-runtime`, target-independent: decision 798), and each
# target's job runs that file (`botopink run --target <t> <bpr>`) from
# `modules/`, the directory of the project that wrote it — the comptime compile,
# the whole cost of the suite (m2-0063's ramp), is paid once for four targets.
# One process per target holds every module (989 (8)); a crash or a hang is that
# target's run red whole.
#
# Decision 996 (L5) joins the libraries and the workspace members here, as lines
# of their own kind in the same program: `roster` then lists them beside the
# modules, and nothing else of this section changes.
root_bpr=""      # the `.bpr` the build wrote, empty when it did not build
root_refusal=""  # why the root package did not build

# The modules of the tree: every directory of `modules/` (and of
# `modules/decisions-taken/`) but the root's own `src/` and the build's dot
# directories, one `<path>` per line, sorted. A module is in decision 989's shape
# when it holds `botopink.json`, `src/main.bp` and `snapshot/main.snap`.
module_dirs() {
    (cd "$here/modules" && for d in */ decisions-taken/*/; do
        d="${d%/}"
        case "$d" in src|decisions-taken|'*'|'decisions-taken/*') continue ;; esac
        [ -d "$d" ] && printf '%s\n' "$d"
    done) | LC_ALL=C sort
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
roster() {
    local d slug
    while IFS= read -r d; do
        slug="$(printf '%s' "$d" | tr '/.' '__')"
        if ! in_shape "$d"; then
            printf '*\tmodules/%s\tfail\t%s\n' "$d" "not in decision 989's shape (no botopink.json, src/main.bp and snapshot/main.snap): 990 (6)'s conversion" >"$work/r-plan-$slug"
        elif ! listed_modules | grep -qxF -- "$d"; then
            printf '*\tmodules/%s\tfail\t%s\n' "$d" "a module with no \`runModule(\"$d\")\` line in modules/src/main.bp" >"$work/r-plan-$slug"
        fi
    done < <(module_dirs)
    while IFS= read -r d; do
        in_shape "$d" && continue
        slug="$(printf '%s' "$d" | tr '/.' '__')"
        [ -f "$work/r-plan-$slug" ] && continue
        printf '*\tmodules/%s\tfail\t%s\n' "$d" "modules/src/main.bp runs \`$d\`, which is no module in decision 989's shape" >"$work/r-plan-$slug"
    done < <(listed_modules)
}

# Build the root package once: `root_bpr` the `.bpr` it wrote, or `root_refusal`
# what the build printed (its first error lines).
build_root() {
    local dir="$work/root" code
    mkdir -p "$dir"
    export BOTOPINK_LIB_ROOTS="$lib_root"
    (cd "$here/modules" && with_timeout 7200 "$compiler" build --emit-runtime "$dir/rt" --out "$dir/out" ${cold_flag[@]+"${cold_flag[@]}"} >"$dir/o.txt" 2>"$dir/e.txt")
    code=$?
    if [ $code -eq 0 ] && [ -f "$dir/rt/conformance.bpr" ]; then
        root_bpr="$dir/rt/conformance.bpr"
    else
        root_refusal="the root package does not build (botopink build --emit-runtime: exit $code): $(strip <"$dir/e.txt" | grep -m3 -E 'error' | tr '\t\n' '  ')"
    fi
}

# One target's run of the root package: one result line per module the program
# printed a verdict for (`<t>\tmodules/<m>\tok|fail\t…`, a red module's lines under
# its verdict kept as its log), and a red of its own when the run ended without
# its summary or with fewer verdicts than lines.
run_root() { # <target> <out file>
    local t="$1" out="$2" dir="$work/root-$1" code
    mkdir -p "$dir"
    if [ -z "$ROOT_BPR" ]; then
        printf '%s\t%s\t%s\t%s\n' "$t" modules fail "$ROOT_REFUSAL" >"$out"
        return
    fi
    (cd "$here/modules" && with_timeout 7200 "$compiler" run --target "$t" --out "$dir/out" "$ROOT_BPR" >"$dir/o.txt" 2>"$dir/e.txt")
    code=$?
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

run_one() { # <path> <target>
    local path="$1" t="$2" slug dir out
    slug="$(printf '%s-%s' "$path" "$t" | tr '/.' '__')"
    dir="$work/p-$slug"; out="$work/r-$slug"
    rm -rf "$dir"
    export BOTOPINK_LIB_ROOTS="$lib_root"
    case "$path" in
        modules) run_root "$t" "$out" ;;
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
        (cd "$dir" && with_timeout 300 "$compiler" build --target "$t" ${cold_flag[@]+"${cold_flag[@]}"} >"$dir/o.txt" 2>"$dir/e.txt")
        code=$?
    else
        : >"$dir/o.txt"; : >"$dir/e.txt"
    fi
    if [ $code -eq 0 ]; then
        (cd "$dir" && with_timeout 300 "$compiler" test --target "$t" ${cold_flag[@]+"${cold_flag[@]}"} >"$dir/o.txt" 2>"$dir/e.txt")
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
export -f run_one run_root test_project json_tests strip quiet project audit_one pool_job pool_admit pool_cpus with_timeout
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
        # The root package: one job per target of the run, each running the one `.bpr`.
        modules)
            for t in "${targets[@]}"; do printf '%s\t%s\trun\n' "$f" "$t" >>"$jobs_list"; done ;;
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
        *) echo "run.sh: not the root package or a suite (modules, test/<name>.bp, test/<project>): $f" >&2; exit 2 ;;
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
# here, before the pool: its targets' jobs only run the `.bpr`.
ROOT_BPR=""; ROOT_REFUSAL=""; ROOT_LISTED=0
if grep -q '^modules	' "$jobs_list"; then
    roster
    build_root
    ROOT_BPR="$root_bpr"; ROOT_REFUSAL="$root_refusal"
    ROOT_LISTED="$(listed_modules | grep -c . || true)"
fi
export ROOT_BPR ROOT_REFUSAL ROOT_LISTED
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
node - "$work/results" "$jobs_ran" "$jobs_audit" "$work" <<'EOF'
const fs = require("fs");
const [resultsPath, jobsRan, jobsAudit, work] = process.argv.slice(2);
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
  const log = `${work}/log-${t}-${key.replace(/[/.]/g, "_")}`;
  if (fs.existsSync(log)) {
    for (const l of fs.readFileSync(log, "utf8").replace(/\n$/, "").split("\n")) out.push(`    ${l}`);
  }
  fails++;
  tally(t, "fail");
}
for (const l of out) console.log(l);
if (audited) console.log(`narrowings: ${audited} exclusion${audited === 1 ? "" : "s"} audited — each stands on a host binding the target does not have`);
const order = ["commonJS", "erlang", "wasm", "beam", "*"];
const keys = [...byTarget.keys()].sort((a, b) => order.indexOf(a) - order.indexOf(b));
if (keys.length) console.log(`by target: ${keys.map((t) => `${t} ${byTarget.get(t).ok}/${byTarget.get(t).ok + byTarget.get(t).fail}`).join(" · ")}`);
console.log(`cells: ${jobsRan} jobs — ${jobsRan - jobsAudit} run, ${jobsAudit} audits`);
const colour = fails ? RED : GREEN;
console.log(`\n${colour}conformance: ${oks} passed, ${fails} failed${NC}`);
process.exit(fails ? 1 : 0);
EOF
