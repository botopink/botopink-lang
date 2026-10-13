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
#               runs on wasm too: `botopink test --target wasm`). A cell is one
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
#   --cold      each `botopink` the run spawns gets `--cold` — the code cache of the
#               cells' dependencies is not read (decision 509 (5)); `scripts/gate.sh
#               --cold` passes it
#
# Three kinds, every job (a share of cells, § run) in its own scratch directory:
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
        -h|--help) sed -n '2,61p' "$0"; exit 0 ;;
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
# A cell is one job of the plan: `botopink cell check` builds it in process on
# each target its manifest declares and runs the program with node, erl or
# wasmtime. The cells run in shares (§ run, § in process): one `botopink`
# process checks a share of them, one after another.
# shellcheck source=../scripts/lib/pool.sh
. "$repo/scripts/lib/pool.sh"
[ -n "$jobs" ] || jobs="$(pool_default_jobs)"
pool_check_jobs "$jobs" run.sh

# ── § beam ────────────────────────────────────────────────────────────────────
# `botopink test --target beam` assembles every module of the run beside
# itself and runs each test module's runner with `erl -pa`, and `botopink test
# --target wasm` runs each test unit under wasmtime (decision 513), so `test/`
# suites run on all four targets. A cell reaches every target through
# `botopink cell check`.
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
#     `f` has no `#[@External.<Target>(…)]` for the <t> backend
#     std-unsupported-on-target: std/<m> has no `#[@External.<Target>]` for target '<t>'
#     `#[@BeamMemory]` has no meaning on the <t> backend
#
# — the one reason a program structurally has no row on a target. A target the
# build accepts, or refuses for any other reason, fails the run naming the
# suite; so is a narrowing that names an unknown target, the same one
# twice, or every target (it narrows nothing: delete it). No flag, list or
# environment variable turns the audit off (decision 67); `--self-test` shows
# each refusal firing. A cell's narrowing is the same rule, checked by
# `botopink cell check` itself.
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
    # A cell answering its snapshot, and one that does not: `botopink cell check`
    # runs each, and the red one names its candidate.
    for c in green red; do
        mkdir -p "$suite/modules/$c/src" "$suite/modules/$c/snapshot/output"
        printf 'pub fn main() {\n    @print("ok");\n}\n' >"$suite/modules/$c/src/main.bp"
        printf '{ "name": "%s", "version": "0.0.1", "src": "src/" }\n' "$c" >"$suite/modules/$c/botopink.json"
    done
    printf 'botopink-cell 1\nout ok\n' >"$suite/modules/green/snapshot/output/main.snap"
    printf 'botopink-cell 1\nout not what it prints\n' >"$suite/modules/red/snapshot/output/main.snap"

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
[*] modules/red — botopink cell check: exit 1
    candidate modules/red/snapshot/output/main.snap.new
narrowings: 2 exclusions audited
by target: commonJS 1/2 · erlang 2/3 · wasm 0/2 · beam 1/3 · * 1/4
conformance: 5 passed, 9 failed
WANT
    # The backed suite ran where it said and nowhere else, and the green cell
    # passed: no line may name them.
    if grep -qE 'test/backed|modules/green' "$st/report.txt"; then
        echo "self-test: a narrowing that stands on a host binding, or a green cell, was reported:" >&2
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
    echo "self-test: 4 malformed or unbacked narrowings refused, 1 backed one scheduled on its declared targets alone, a red cell named, 4 abnormal ends of a run (a trap, no summary, fewer results, a bare non-zero exit) red"
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

# A share of the cells — `--list`'s lines, in plan order — checked by ONE
# `botopink cell check --jobs 1 <cell>…` from a scratch directory of the share's
# own (its `.botopinkbuild/tmp/` lands there, and no library root is found above
# it but --lib-root): the process builds each cell in process, one after
# another, and runs its programs (§ in process). Every cell of the share still
# writes its own verdict, read off the verdict line `botopink cell check` prints
# for it (`ok   <cell>`, or `FAIL <cell>` and the lines under it — the
# candidates and their differences, what a person reads, kept beside a red
# cell's verdict). A cell the process left without a verdict line (it died on
# it) is checked again alone, and its verdict is that run's.
check_share() { # <share id> <path…, one per line>
    local id="$1" dir="$work/s-$1" path paths=() abs=() code
    while IFS= read -r path; do [ -n "$path" ] && { paths+=("$path"); abs+=("$here/$path"); }; done <<<"$2"
    mkdir -p "$dir"
    (cd "$dir" && with_timeout $((3600 * ${#paths[@]})) "$compiler" cell check --jobs 1 ${cold_flag[@]+"${cold_flag[@]}"} "${abs[@]}" >"$dir/cell.txt" 2>&1)
    code=$?
    for path in "${paths[@]}"; do
        verdict_of "$dir/cell.txt" "$path" "$code" || {
            local alone="$dir/alone-$(printf '%s' "$path" | tr '/.' '__')"
            mkdir -p "$alone"
            (cd "$alone" && with_timeout 3600 "$compiler" cell check --jobs 1 ${cold_flag[@]+"${cold_flag[@]}"} "$here/$path" >"$alone/cell.txt" 2>&1)
            verdict_of "$alone/cell.txt" "$path" "$?" whole
        }
    done
}

# The verdict of the cell <path> in what `botopink cell check` printed (<file>):
# its section — the verdict line naming it and every indented line under it.
# Returns 1 when no verdict line names the cell, unless `whole` is given: then
# the cell fails and the whole output is its log.
verdict_of() { # <file> <path> <exit code> [whole]
    local file="$1" path="$2" code="$3" slug out
    slug="$(printf '%s-%s' "$path" '*' | tr '/.*' '___')"
    out="$work/r-$slug"
    strip <"$file" | awk -v want="$here/$path" '
        function verdict(l) { return substr(l, 1, 5) == "ok   " || substr(l, 1, 5) == "FAIL " }
        verdict($0) {
            rest = substr($0, 6)
            on = (rest == want || index(rest, want " — ") == 1)
            if (on) print
            next
        }
        on { print }' >"$out.section"
    local first; first="$(head -n1 "$out.section")"
    case "$first" in
        "ok   "*)
            printf '*\t%s\t%s\t\n' "$path" ok >"$out" ;;
        "FAIL "*)
            printf '*\t%s\t%s\t%s\n' "$path" fail "botopink cell check: exit 1" >"$out"
            sed "s#$here/##g" <"$out.section" >"$work/log-$(basename "$out")" ;;
        *)
            if [ "${4:-}" != whole ]; then rm -f "$out.section"; return 1; fi
            printf '*\t%s\t%s\t%s\n' "$path" fail "botopink cell check: exit $code, no verdict for the cell" >"$out"
            strip <"$file" | sed "s#$here/##g" >"$work/log-$(basename "$out")" ;;
    esac
    rm -f "$out.section"
}

run_one() { # <path> <target>
    local path="$1" t="$2" slug dir out
    slug="$(printf '%s-%s' "$path" "$t" | tr '/.' '__')"
    dir="$work/p-$slug"; out="$work/r-$slug"
    rm -rf "$dir"
    export BOTOPINK_LIB_ROOTS="$lib_root"
    case "$path" in
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
    export BOTOPINK_LIB_ROOTS="$lib_root"
    local code
    case "$path" in
        # A single-file suite carries its host binding in the test file: the refusal
        # shows when the suite is compiled for the target, so it is `test` that is run.
        *.bp)
            project "$dir"
            cp "$here/$path" "$dir/test/$(basename "$path")"
            (cd "$dir" && with_timeout 300 "$compiler" test --target "$t" ${cold_flag[@]+"${cold_flag[@]}"} >"$dir/o.txt" 2>"$dir/e.txt")
            code=$? ;;
        *)
            cp -R "$here/$path" "$dir"
            (cd "$dir" && with_timeout 300 "$compiler" build --target "$t" ${cold_flag[@]+"${cold_flag[@]}"} >"$dir/o.txt" 2>"$dir/e.txt")
            code=$? ;;
    esac
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
export -f run_one check_share verdict_of test_project json_tests strip quiet project audit_one pool_job pool_admit pool_cpus with_timeout
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
  // A single-file suite narrows itself with one `// targets: <t> <t>…` line.
  for (const f of dirs) {
    if (!f.endsWith(".bp")) continue;
    const m = /^\/\/ targets:[ \t]*(.*)$/m.exec(fs.readFileSync(path.join(root, "test", f), "utf8"));
    if (m) console.log(`test/${f}\t${/^([A-Za-z]+[ \t]*)*$/.test(m[1]) ? m[1].trim().split(/[ \t]+/).join(" ") : "!"}`);
  }' "$here" >"$work/manifest-targets"

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
        echo "run.sh: no such cell or suite: $f" >&2; exit 2
    fi
    case "$f" in
        # A cell is one job: `botopink cell check` runs every target it declares.
        modules/*) printf '%s\t*\trun\n' "$f" >>"$jobs_list" ;;
        test/*.bp|test/*)
            declared="$(awk -F '\t' -v c="$f" '$1 == c { print $2 }' "$work/manifest-targets")"
            case "$f" in *.bp) narrow_by="$f \`// targets:\` line"; narrow_bad="$f's \`// targets:\` line is not a list of target names" ;; *) narrow_by="$f/botopink.json \"targets\""; narrow_bad="$f/botopink.json is not JSON, or its \"targets\" is not an array of target names" ;; esac
            if [ "$declared" = "!" ]; then
                printf '*\t%s\tfail\t%s\n' "$f" "$narrow_bad" >"$work/r-narrowing-$(printf '%s' "$f" | tr '/.' '__')"
            elif [ -n "$declared" ]; then
                narrowed "$f" "$narrow_by" "$declared"
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

# ── § run ─────────────────────────────────────────────────────────────────────
# Decision 510: every job runs on every run — no verdict is stored nor answered
# from a store. The jobs are the plan's lines, in plan order.
#
# § in process: the cells (target `*`) go to the pool in shares — about two per
# job, at most 32 cells each — and a share is one `botopink cell check`
# process that builds its cells in process one after another (144 B-29 step
# H): no `botopink` process per cell. Each cell keeps its own verdict, so the
# report, its counts and `--list`'s plan are the cells', not the shares'.
cells_total="$(awk -F '\t' '$2 == "*"' "$jobs_list" | wc -l | tr -d ' ')"
share=1
if [ "$cells_total" -gt 0 ]; then
    share=$(( (cells_total + 2 * jobs - 1) / (2 * jobs) ))
    [ "$share" -le 32 ] || share=32
fi
{
    awk -F '\t' '$2 == "*" { print $1 }' "$jobs_list" | awk -v n="$share" '
        { batch = batch $0 "\n"; if (++k == n) { printf "check_share%c%d%c%s%c-%c", 0, ++id, 0, batch, 0, 0; batch = ""; k = 0 } }
        END { if (k) printf "check_share%c%d%c%s%c-%c", 0, ++id, 0, batch, 0, 0 }'
    while IFS=$'\t' read -r f t what; do
        case "$what" in
            audit:*) printf 'audit_one\0%s\0%s\0%s\0' "$f" "$t" "${what#audit:}" ;;
            # The 4th field is `-`, never empty: BSD xargs (macOS) drops an empty
            # argument even under -0, and every later group of 4 would shift.
            *) [ "$t" = "*" ] || printf 'run_one\0%s\0%s\0-\0' "$f" "$t" ;;
        esac
    done <"$jobs_list"
} | xargs -0 -r -n 4 -P "$jobs" bash -c 'pool_job "$work/inflight" "$0" "$1" "$2" "$3"'

cat "$work"/r-* 2>/dev/null | sort >"$work/results"
# How many jobs wrote their verdict — every job writes exactly one file
# (`r-<slug>`, `r-audit-<slug>`); a malformed narrowing writes `r-narrowing-*`
# without a job. `scripts/gate.sh` compares the count with `--list`.
jobs_audit="$(ls "$work" | grep -c '^r-audit-' || true)"
jobs_ran="$(( $(ls "$work" | grep '^r-' | grep -vc '^r-narrowing-') ))"

# ── report ────────────────────────────────────────────────────────────────────
node - "$work/results" "$jobs_ran" "$jobs_audit" "$work" <<'EOF'
const fs = require("fs");
const [resultsPath, jobsRan, jobsAudit, work] = process.argv.slice(2);
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
const colour = fails ? RED : GREEN;
console.log(`\n${colour}conformance: ${oks} passed, ${fails} failed${NC}`);
process.exit(fails ? 1 : 0);
EOF
