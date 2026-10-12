#!/usr/bin/env bash
# run.sh — botopink-lang's conformance suite (decisions 457, 464, 466, 475):
# every cell of `modules/` checked by `botopink cell check`, and every `test/`
# suite run by `botopink test --json` (`zig build test-conformance`, the gate's
# conformance stage).
#
# Usage:
#   conformance/run.sh [--target commonJS|erlang|wasm|beam|all|<t>,<t>…]
#                      [--compiler <botopink>]
#                      [--lib-root <dir>] [--only <path>] [--jobs <n>] [--list]
#   conformance/run.sh --self-test [--compiler <botopink>] [--lib-root <dir>]
#
#   --target    the targets the `test/` suites run on; default `all` (a suite
#               never runs on wasm: `botopink test` refuses it). A cell is one
#               job whatever the target: `botopink cell check` runs it on every
#               target its manifest declares. A missing runtime fails the run;
#               it never drops a target (decision 67).
#   --compiler  the `botopink` binary; default <repo>/zig-out/bin/botopink
#   --lib-root  where `from "std"` resolves; default <compiler>/../../libs
#   --only      run one cell or suite (e.g. modules/case_range_value,
#               test/case_arms.bp, test/pub_val_in_a_test); may repeat
#   --jobs      parallel jobs; default one per CPU, bounded by memory
#               (MemAvailable / 768 MiB) — § parallel jobs below
#   --list      print the plan and run nothing: one `<path>\t<target>\t<run|audit>`
#               line per job (a cell's target is `*`). A whole run ends with
#               `cells: <J> jobs — <R> run, <A> audits`, and `scripts/gate.sh`
#               holds J to the number of lines `--list` prints: a run cannot
#               do fewer jobs than the tree declares
#   --suite     the directory holding modules/ and test/; default this
#               script's own. `--self-test` is its one caller.
#   --self-test prove § the targets of a test suite against synthetic suites:
#               a narrowing the compiler does not back fails the run, one it
#               backs schedules the suite on the declared targets alone. A
#               whole run of the suite (no --only) starts with it. (A cell's
#               narrowing is `botopink cell check`'s, proved by
#               modules/compiler-cli/tests/cli_contract.sh.)
#   --cold      run every job; the result store is not read, and the passes are
#               written to it (§ the result store); `scripts/gate.sh --cold`
#               passes it; each `botopink` the run spawns gets `--cold` too —
#               the code cache of the cells' dependencies is not read (decision
#               509 (5))
#   --store-root  the result store's directory; default
#               <repo>/.botopinkbuild/cache/results/conformance
#
# Three kinds, every job in its own scratch directory:
#   modules/<cell>/    a cell (decisions 457, 475): `botopink.json`, `src/`,
#                      `snapshot/output/<module>.snap`, `snapshot/targets/<t>/
#                      <module>.snap` where a target departs, `docs.md`.
#                      `botopink cell check <cell>` builds and runs it on every
#                      target its manifest declares (all four, or its
#                      `"targets"`, each excluded target audited against a
#                      host-binding refusal) and compares every module's answer
#                      with its snapshots; a mismatch writes a `.snap.new`
#                      candidate beside the accepted file and fails the job
#                      (modules/compiler-cli/AGENTS.md § Cells).
#   test/<name>.bp     `test "…" { … assert … }` blocks: `botopink test --target
#                      <t> --json` in a scratch project; every test must pass
#   test/<name>/       a whole project with a `test/` tree: `botopink test
#                      --target <t> --json`, keyed <name>::<test>. `"targets"`
#                      in its botopink.json narrows it, audited — § the targets
#                      of a test suite
#
# Outcome rules: a job passes or it fails, and a run fails on any `FAIL`. There
# is no list of known failures (decision 154): a red cell is red until the
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
        -h|--help) sed -n '2,65p' "$0"; exit 0 ;;
        *) echo "run.sh: unknown argument '$1'" >&2; exit 2 ;;
    esac
done
# `--cold` handed on to every `botopink build` / `test` / `cell check` (decision 509 (5)).
cold_flag=()
[ "$cold" -eq 0 ] || cold_flag=(--cold)
runner="$here/$(basename "${BASH_SOURCE[0]}")"
# The cells are read from `$here`; `--suite` points it at another tree.
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
# A cell is one job: `botopink cell check` builds it in process on each target
# its manifest declares and runs the program with node, erl or wasmtime.
# shellcheck source=../scripts/lib/pool.sh
. "$repo/scripts/lib/pool.sh"
[ -n "$jobs" ] || jobs="$(pool_default_jobs)"
pool_check_jobs "$jobs" run.sh

# ── § beam ────────────────────────────────────────────────────────────────────
# `botopink test --target beam` assembles every module of the run beside
# itself and runs each test module's runner with `erl -pa`, so `test/` suites
# run on beam too; `botopink test` refuses wasm alone, so a suite never runs
# there. A cell reaches every target through `botopink cell check`.
#
# `erlc` and `erl` are gate dependencies already, so beam costs no new tool; a
# machine without them fails the run below rather than run fewer targets and
# say "all".
#
# ── § the targets of a test suite ─────────────────────────────────────────────
# A `test/` suite runs on commonJS, erlang and beam unless a project suite
# NARROWS itself with `"targets"` in its `botopink.json`. A narrowing is a
# claim about the compiler, and the runner checks it on every run: for each
# target of the run the suite excludes, `botopink build --target <t>` in the
# project must REFUSE it on a host binding —
#
#     `f` has no `#[@External.<Target>(…)]` for the <t> backend
#     std-unsupported-on-target: std/<m> has no `#[@External.<Target>]` for target '<t>'
#     `#[@BeamMemory]` has no meaning on the <t> backend
#
# — the one reason a program structurally has no row on a target. A target the
# build accepts, or refuses for any other reason, fails the run naming the
# suite; so is a narrowing that names wasm, an unknown target, the same one
# twice, or every target (it narrows nothing: delete it). No flag, list or
# environment variable turns the audit off (decision 67); `--self-test` shows
# each refusal firing. A cell's narrowing is the same rule, checked by
# `botopink cell check` itself.
ALL_TARGETS="commonJS erlang wasm beam"
TEST_TARGETS="commonJS erlang beam"
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
# A cell runs on every target it declares, whatever --target says: the tools of
# all four are needed whenever a cell is in the plan.
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
# of each way a narrowing is refused, and a passing and a red cell — is run
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
#[@External.Erlang("""1""")]
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
    project_suite names_wasm '["commonJS", "wasm"]' <<'BP'
pub fn one() -> i32 {
    return 1;
}
BP
    project_suite narrows_nothing '["commonJS", "erlang", "beam"]' <<'BP'
pub fn one() -> i32 {
    return 1;
}
BP
    project_suite unknown_target '["commonJS", "jvm"]' <<'BP'
pub fn one() -> i32 {
    return 1;
}
BP
    # A cell answering its snapshot, and one that does not: `botopink cell check`
    # runs each, and the red one names its candidate.
    for c in green red; do
        mkdir -p "$suite/modules/$c/src" "$suite/modules/$c/snapshot/output"
        printf 'pub fn main() {\n    @print("ok");\n}\n' >"$suite/modules/$c/src/main.bp"
        printf '{ "name": "%s", "version": "0.0.1", "src": "src/" }\n' "$c" >"$suite/modules/$c/botopink.json"
    done
    printf 'botopink-cell 1\nout ok\n' >"$suite/modules/green/snapshot/output/main.snap"
    printf 'botopink-cell 1\nout not what it prints\n' >"$suite/modules/red/snapshot/output/main.snap"

    # `--cold`: the runner's own proof runs every synthetic job, every time,
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
[beam] test/unbacked — excluded by test/unbacked/botopink.json "targets", but `botopink build --target beam` accepts the suite
[beam] test/another_reason — excluded by test/another_reason/botopink.json "targets", and beam refuses it for another reason than a host binding
[*] test/names_wasm — test/names_wasm/botopink.json "targets" names wasm, a target a test suite never runs on
[*] test/narrows_nothing — test/narrows_nothing/botopink.json "targets" names every target the suite runs on, so it narrows nothing
[*] test/unknown_target — test/unknown_target/botopink.json "targets" names `jvm`, which is no target
[*] modules/red — botopink cell check: exit 1
    candidate modules/red/snapshot/output/main.snap.new
narrowings: 1 exclusion audited
by target: commonJS 1/2 · erlang 2/3 · beam 1/3 · * 1/5
conformance: 5 passed, 8 failed
WANT
    # The backed suite ran where it said and nowhere else, and the green cell
    # passed: no line may name them.
    if grep -qE 'test/backed|modules/green' "$st/report.txt"; then
        echo "self-test: a narrowing that stands on a host binding, or a green cell, was reported:" >&2
        grep -E 'test/backed|modules/green' "$st/report.txt" >&2
        missing=1
    fi
    if [ $missing -ne 0 ]; then
        echo "self-test: FAILED — the synthetic suite's report was:" >&2
        sed 's/^/    /' "$st/report.txt" >&2
        return 1
    fi
    echo "self-test: 5 malformed or unbacked narrowings refused, 1 backed one scheduled on its declared targets alone, a red cell named"
}

# ── collect the jobs' paths ───────────────────────────────────────────────────
files=()
if [ ${#only[@]} -gt 0 ]; then
    files=("${only[@]}")
else
    while IFS= read -r f; do files+=("$f"); done < <(cd "$here" && { ls test/*.bp 2>/dev/null; ls -d test/*/ modules/*/ 2>/dev/null | sed 's:/$::'; } | sort)
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
    local dir="$1" path="$2" t="$3" out="$4"
    (cd "$dir" && with_timeout 300 "$compiler" test --target "$t" --json ${cold_flag[@]+"${cold_flag[@]}"} >"$dir/o.json" 2>"$dir/e.txt")
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

# `botopink cell check <cell>` from a scratch directory (its `.botopinkbuild/tmp/`
# lands there, and no library root is found above it but --lib-root). Its whole
# output is kept beside the verdict for a red cell: the candidates and the diffs
# are what a person reads.
check_cell() { # <dir> <path> <out>
    local dir="$1" path="$2" out="$3"
    mkdir -p "$dir"
    (cd "$dir" && with_timeout 3600 "$compiler" cell check ${cold_flag[@]+"${cold_flag[@]}"} "$here/$path" >"$dir/cell.txt" 2>&1)
    local code=$?
    if [ $code -eq 0 ]; then
        printf '*\t%s\t%s\t\n' "$path" ok >"$out"
    else
        printf '*\t%s\t%s\t%s\n' "$path" fail "botopink cell check: exit $code" >"$out"
        strip <"$dir/cell.txt" | sed "s#$here/##g" >"$work/log-$(basename "$out")"
    fi
}

run_one() { # <path> <target>
    local path="$1" t="$2" slug dir out
    slug="$(printf '%s-%s' "$path" "$t" | tr '/.' '__')"
    dir="$work/p-$slug"; out="$work/r-$slug"
    rm -rf "$dir"
    export BOTOPINK_LIB_ROOTS="$lib_root"
    case "$path" in
        modules/*) check_cell "$dir" "$path" "$out" ;;
        test/*.bp)
            project "$dir"
            cp "$here/$path" "$dir/test/$(basename "$path")"
            test_project "$dir" "$path" "$t" "$out" ;;
        test/*)
            cp -R "$here/$path" "$dir"
            test_project "$dir" "$path" "$t" "$out" ;;
        *) printf '*\t%s\t%s\t%s\n' "$path" fail "not under modules/ or test/" >"$out" ;;
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
    cp -R "$here/$path" "$dir"
    export BOTOPINK_LIB_ROOTS="$lib_root"
    (cd "$dir" && with_timeout 300 "$compiler" build --target "$t" ${cold_flag[@]+"${cold_flag[@]}"} >"$dir/o.txt" 2>"$dir/e.txt")
    local code=$?
    quiet <"$dir/o.txt" >"$dir/all.txt"; quiet <"$dir/e.txt" >>"$dir/all.txt"
    if [ $code -eq 0 ]; then
        printf '%s\t%s\t%s\t%s\n' "$t" "$path" fail "excluded by $by, but \`botopink build --target $t\` accepts the suite — a narrowing stands on a host-binding refusal: let it run on $t, and a red there is a row of that backend's front" >"$out"
    elif grep -qF -e 'has no `#[@External.<Target>(' -e 'std-unsupported-on-target:' -e '`#[@BeamMemory]` has no meaning on the '"$t"' backend' "$dir/all.txt"; then
        printf '%s\t%s\t%s\t\n' "$t" "$path" audit >"$out"
    else
        local first; first="$(grep -m1 -iE 'error' "$dir/all.txt" | tr '\t' ' ')"
        printf '%s\t%s\t%s\t%s\n' "$t" "$path" fail "excluded by $by, and $t refuses it for another reason than a host binding (got: ${first:-no error line}) — let the suite run there" >"$out"
    fi
}
export -f run_one check_cell test_project json_tests strip quiet project audit_one pool_job pool_admit pool_cpus with_timeout
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
  }' "$here" >"$work/manifest-targets"

# Schedule <suite> under the narrowing <declared…> written in <by>: a run job on
# each target of the run the suite keeps, an audit job on each one it excludes —
# or one `*` failure when the narrowing itself is malformed.
narrowed() { # <path> <by> <declared>
    local f="$1" by="$2" declared="$3" t d seen="" why=""
    for d in $declared; do
        case " $ALL_TARGETS " in *" $d "*) ;; *) why="names \`$d\`, which is no target"; break ;; esac
        case " $TEST_TARGETS " in *" $d "*) ;; *) why="names $d, a target a test suite never runs on"; break ;; esac
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
        echo "run.sh: no such cell or suite: $f" >&2; exit 2
    fi
    case "$f" in
        # A cell is one job: `botopink cell check` runs every target it declares.
        modules/*) printf '%s\t*\trun\n' "$f" >>"$jobs_list" ;;
        test/*.bp)
            for t in "${targets[@]}"; do
                case " $TEST_TARGETS " in *" $t "*) printf '%s\t%s\trun\n' "$f" "$t" >>"$jobs_list" ;; esac
            done ;;
        test/*)
            declared="$(awk -F '\t' -v c="$f" '$1 == c { print $2 }' "$work/manifest-targets")"
            if [ "$declared" = "!" ]; then
                printf '*\t%s\tfail\t%s\n' "$f" "$f/botopink.json is not JSON, or its \"targets\" is not an array of target names" >"$work/r-narrowing-$(printf '%s' "$f" | tr '/.' '__')"
            elif [ -n "$declared" ]; then
                narrowed "$f" "$f/botopink.json \"targets\"" "$declared"
            else
                for t in "${targets[@]}"; do
                    case " $TEST_TARGETS " in *" $t "*) printf '%s\t%s\trun\n' "$f" "$t" >>"$jobs_list" ;; esac
                done
            fi ;;
        *) echo "run.sh: not a cell or a suite (modules/<cell>, test/<name>.bp, test/<project>): $f" >&2; exit 2 ;;
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
# and the job's target's own; every target's for a cell, which runs on all the
# targets it declares), this script, pool.sh and result-store.js, the toolchain
# (node, the OTP release, wasmtime, the environment a compiler or runtime
# reads), every file of the library root (`--lib-root`, where `from "std"`
# resolves), and the job's own files — `test/<n>.bp`, or the whole
# `test/<n>/` or `modules/<cell>/` tree (sources, manifest, snapshots) — with
# the target and the job's kind. No analysis decides what a change can affect:
# a key that differs in one byte runs the job. Only a verdict whose every line
# is `ok` (or an audited exclusion) is written, and only when the job's key is
# the same after the run as before it (nothing moved under it — a red cell's
# candidates do move it, and a red verdict is never stored anyway). A job whose
# inputs cannot be enumerated with certainty is never stored, and the report
# says why (result-store.js: a symbolic link, a dependency that leaves the
# cell, a library root above the scratch directory). The store lives in
# `<repo>/.botopinkbuild/cache/results/conformance/` (decision 225): deleting
# `.botopinkbuild/` wipes it; `--cold` never reads it and writes its passes
# (decision 249), so the warm run after a landing answers from them.
store_js="$repo/scripts/lib/result-store.js"
[ -n "$store_dir" ] || store_dir="$repo/.botopinkbuild/cache/results/conformance"
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
        --global-tree "lib-root=$lib_root" --global-text "conformance" --scratch "$work"
}
while IFS=$'\t' read -r id f t what; do
    inputs="$f"
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
jobs_audit="$(ls "$work" | grep -c '^r-audit-' || true)"
jobs_ran="$(( $(ls "$work" | grep '^r-' | grep -vc '^r-narrowing-') ))"

# ── report ────────────────────────────────────────────────────────────────────
node - "$work/results" "$jobs_ran" "$jobs_audit" "$store_total" "$store_from" "$store_note" "$work/store-never" "$work" <<'EOF'
const fs = require("fs");
const [resultsPath, jobsRan, jobsAudit, storeTotal, storeFrom, storeNote, storeNever, work] = process.argv.slice(2);
const RED = "\x1b[0;31m", GREEN = "\x1b[0;32m", NC = "\x1b[0m";

// <target>\t<key>\t<ok|fail|audit>\t<detail>, sorted. An `audit` line is an
// exclusion the compiler backs with a host-binding refusal: not a cell that
// ran, so not in the `passed` count.
// The per-target line is what a claim of the form "every suite of X has a beam
// result" quotes; `*` is a cell (`botopink cell check`, every target it
// declares) and a malformed narrowing (refused before any target ran). A red
// cell's FAIL line is followed by what `botopink cell check` printed: the
// candidates it wrote and their differences.
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
  if (t === "*" && key.startsWith("modules/")) {
    for (const f of fs.readdirSync(work).filter((n) => n.startsWith(`log-r-${key.replace(/[/.]/g, "_")}-`))) {
      for (const l of fs.readFileSync(`${work}/${f}`, "utf8").replace(/\n$/, "").split("\n")) out.push(`    ${l}`);
    }
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
// § the result store: what was executed and what was answered from a stored
// pass; `scripts/gate.sh` holds run + from store to the plan.
process.stdout.write(fs.readFileSync(storeNever, "utf8"));
console.log(`result store: ${storeTotal} jobs — ${storeTotal - storeFrom} run, ${storeFrom} from store${storeNote}`);
const colour = fails ? RED : GREEN;
console.log(`\n${colour}conformance: ${oks} passed, ${fails} failed${NC}`);
process.exit(fails ? 1 : 0);
EOF
