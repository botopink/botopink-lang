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
#   --jobs      parallel cells, default 4
#
# Four kinds, every cell in its own scratch project (a parse error fails only
# that cell):
#   test/<name>.bp     `botopink test --target <t> --json`; every test must pass
#   run/<name>.bp      `botopink run --target <t>`; stdout must equal <name>.out
#                      (on beam: run, then `erlc +from_asm out/*.S`, then `erl`)
#   reject/<name>.bp   `botopink check`; must exit non-zero, stderr must contain
#                      the first line of <name>.expect and ` --> src/main.bp:<L:C>`
#                      where <L:C> is its second line (target-independent: runs
#                      once, reported as target `*`)
#   modules/<name>/    a whole project — its own `botopink.json` and `src/` tree;
#                      `botopink run --target <t>`; stdout must equal
#                      <name>/expected.out. The kind for what one file cannot
#                      express: `pub mod`, `import … from "<module>"`, `from "std"`
#
# expected-failures.txt — one line per expected failure, `|`-separated (test
# names contain spaces):
#   <target: commonJS|erlang|wasm|beam|*> | <path>[::<test name>] | <owner row> | <reason>
# A path-only entry is allowed only for a file that does not compile.
#
# Outcome rules (a run fails on any `FAIL`):
#   unlisted, passes            ok
#   unlisted, fails             FAIL
#   listed, fails               expected (printed with its owner)
#   listed, passes              FAIL — "now passes: delete its line"
#   listed, does not exist      FAIL — the path or the test name is not there
#   path-only entry on a file that compiles   FAIL — list the failing tests by name
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(cd "$here/../.." && pwd)"

target="all"
compiler="$repo/zig-out/bin/botopink"
lib_root=""
jobs=4
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
        -h|--help) sed -n '2,43p' "$0"; exit 0 ;;
        *) echo "run.sh: unknown argument '$1'" >&2; exit 2 ;;
    esac
done

# ── § beam ────────────────────────────────────────────────────────────────────
# `botopink run --target beam` writes `out/*.S` and stops — BEAM Assembly is an
# artifact, not a run. It is two commands from being one (decision 8, measured at
# `c2dd780`):
#
#     $ botopink run --target beam        # wrote out/main.S
#     $ (cd out && erlc +from_asm *.S)    # main.S → main.beam
#     $ erl -noshell -pa out -eval 'main:main(), halt().'
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
    if [ -f "$dir/out/main.beam" ]; then
        mod=main
    else
        mod="$(cd "$dir/out" && ls -1 ./*.beam 2>/dev/null | head -1)"
        mod="$(basename "${mod%.beam}")"
    fi
    [ -n "$mod" ] || { echo "error: erlc +from_asm produced no .beam" >>"$dir/e.txt"; return 1; }
    (cd "$dir" && timeout 300 erl -noshell -pa out -eval "$mod:main(), halt()." \
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
            cp "$here/$path" "$dir/src/main.bp"
            exec_run "$dir" "$t"
            local code=$?
            if [ ! -f "$expected" ]; then
                printf '%s\t%s\t%s\t%s\n' "$t" "$path" fail "missing ${path%.bp}.out" >"$out"
            elif [ $code -eq 0 ] && cmp -s "$dir/stdout.txt" "$expected"; then
                printf '%s\t%s\t%s\t\n' "$t" "$path" ok >"$out"
            else
                local got; got="$(head -c 300 "$dir/stdout.txt" | tr '\n\t' '⏎ ')"
                local err; err="$(strip <"$dir/e.txt" | grep -m1 -iE 'error' | tr '\t' ' ')"
                printf '%s\t%s\t%s\t%s\n' "$t" "$path" fail "exit $code; stdout: $got ${err:+; $err}" >"$out"
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
            exec_run "$dir" "$t"
            local code=$?
            if [ ! -f "$expected" ]; then
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
export -f run_one json_tests strip quiet project exec_run
export here work compiler lib_root

# ── dispatch ──────────────────────────────────────────────────────────────────
jobs_list="$work/jobs"
: >"$jobs_list"
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
        *) for t in "${targets[@]}"; do printf '%s\t%s\n' "$f" "$t" >>"$jobs_list"; done ;;
    esac
done
while IFS=$'\t' read -r f t; do
    if [ "$t" = "*" ]; then printf '%s\0%s\0' "$f" "${targets[0]}"; else printf '%s\0%s\0' "$f" "$t"; fi
done <"$jobs_list" | xargs -0 -n 2 -P "$jobs" bash -c 'run_one "$0" "$1"'

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

const expected = [];
if (fs.existsSync(listPath)) {
  fs.readFileSync(listPath, "utf8").split("\n").forEach((raw, i) => {
    const line = raw.trim();
    if (!line || line.startsWith("#")) return;
    const parts = line.split("|").map((s) => s.trim());
    if (parts.length < 4 || !parts[2] || !parts[3]) {
      expected.push({ bad: `expected-failures.txt:${i + 1}: needs 4 fields <target> | <path>[::test] | <owner> | <reason>` });
      return;
    }
    expected.push({ target: parts[0], key: parts[1], owner: parts[2], reason: parts.slice(3).join(" | "), line: i + 1 });
  });
}

let fails = 0, oks = 0, expectedCount = 0;
const out = [];
const claimed = new Set();
for (const e of expected) {
  if (e.bad) { out.push(`${RED}FAIL${NC}     ${e.bad}`); fails++; continue; }
  const ts = e.target === "*" ? ["*", ...targets] : [e.target];
  if (e.target !== "*" && !targets.includes(e.target)) continue; // not run this time
  let found = false;
  for (const t of ts) {
    const path = e.key.split("::")[0];
    if (!e.key.includes("::") && compiled.has(`${t}\t${path}`)) {
      found = true;
      out.push(`${RED}FAIL${NC}     [${t}] ${e.key} — compiles: list its failing tests by name (expected-failures.txt:${e.line})`);
      fails++;
      continue;
    }
    const r = results.get(`${t}\t${e.key}`);
    if (!r) continue;
    found = true;
    claimed.add(`${t}\t${e.key}`);
    if (r.status === "ok") {
      out.push(`${RED}FAIL${NC}     [${t}] ${e.key} — now passes: delete its line (expected-failures.txt:${e.line})`);
      fails++;
    } else {
      out.push(`${YELLOW}expected${NC} [${t}] ${e.key} — ${e.owner}: ${e.reason}`);
      expectedCount++;
    }
  }
  if (!found) {
    const path = e.key.split("::")[0];
    const fileRan = [...results.keys()].some((k) => k.split("\t")[1].split("::")[0] === path);
    if (partial && !fileRan) continue; // --only run that skipped this file
    out.push(`${RED}FAIL${NC}     ${e.key} — listed (line ${e.line}) but no such ${e.key.includes("::") && fileRan ? "test" : "file or result"} for target ${e.target}`);
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
