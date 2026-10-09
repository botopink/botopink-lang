#!/usr/bin/env bash
# check-docs.sh — every `botopink` fence in the user docs is compiled, and every
# fence that claims a refusal is refused (`zig build test-docs`).
#
# Usage:
#   scripts/check-docs.sh [--compiler <botopink>] [--doc <file>]… [--list] [--jobs <n>] [--self-test]
#                         [--cold] [--store-root <dir>] [--lib-root <dir>]…
#
#   --compiler  the `botopink` binary; default <repo>/zig-out/bin/botopink
#   --doc       a markdown file to check (relative to the repository, or
#               absolute); repeatable, default `docs.md README.md`
#   --list      print every fence with its directive and exit (compiles nothing)
#   --jobs      parallel `botopink check` runs; default one per CPU, bounded by
#               memory (scripts/lib/pool.sh). The report is printed in fence
#               order whatever the count, so `--jobs 1` prints the same bytes
#   --self-test run only the harness's own contract (below) and exit
#   --cold      check every fence; the result store is not read, and the passes
#               are written to it (below); `scripts/gate.sh --cold` passes it
#   --store-root  the result store's directory; default
#               <repo>/.botopinkbuild/cache/results/docs
#   --lib-root  a library root a fence's `dependencies` resolve through, in
#               place of the default list (below); repeatable. A harness test
#               names its own, so its keys never read a sibling checkout
#
# A fence is ```botopink. What the checker does with it is decided by an HTML
# comment on the line just above the fence (invisible in rendered markdown, and
# the fence keeps its `botopink` highlighting):
#
#   (no comment)                     a whole module → written as src/main.bp;
#                                    must compile
#   <!-- docs-check: body -->        statements → wrapped in `fn main() { … }`;
#                                    must compile
#   <!-- docs-check: project <name> <path> -->
#                                    one file of a multi-file project; every
#                                    fence with the same <name> is written at
#                                    its <path> and the project is checked once
#                                    (one of them must be src/main.bp). The
#                                    fence may be of any language: a ```json
#                                    fence at botopink.json is the project's
#                                    manifest, whose `dependencies` resolve by
#                                    name through the checkout's library roots
#                                    (libs/ and the sibling checkouts next to
#                                    this repository or under repository/)
#   <!-- docs-check: reject [body] <expectation> -->
#                                    code the compiler must REFUSE: `botopink
#                                    check` must exit non-zero and its first
#                                    `error` line must contain <expectation> —
#                                    an error id (`iter-await`) or a message
#                                    (`'f' expects 2 argument(s), got 0`), the
#                                    rest of the comment verbatim. `body` wraps
#                                    the statements in `fn main() { … }` first.
#                                    A reject fence that compiles, or that is
#                                    refused with another first diagnostic,
#                                    fails the run: the doc claims a refusal
#                                    the compiler does not make. One refusal
#                                    per fence — the checker stops at the first
#
# There is no directive that skips a fence (1.0.11-beta, decision gate-e): a
# table, a grammar or a layout sample is not code and is fenced as ```text; a
# fence the harness cannot check is a fence the doc cannot make a claim with.
# A fence that fails, an unknown directive, a directive on a fence that is not
# ```botopink (`project` excepted), a `reject` with no expectation and a
# project with no `src/main.bp` all fail the run.
#
# Each module or project is checked with `botopink check` in a scratch project
# (`{ "target": "commonJS" }`; `check` is target-independent).
#
# Every run starts with the harness's own contract — a synthetic doc whose nine
# fences must get known verdicts (a `reject` that compiles ✗, one refused with
# another diagnostic ✗, the right one ✓, a `reject body` ✓, a `skip` directive
# ✗, a module that does not compile ✗, one that does ✓, a `reject` with no
# expectation ✗, a `body` directive on a ```text fence ✗). A verdict that
# differs fails the run before the docs are judged; `--self-test` runs only it.
#
# The result store (decisions 229 and 249, front 00-gate/133-gate-speed): a
# check whose key equals the key of a stored PASS is answered from the store,
# and every other check runs. The key is the SHA-256 of every byte the check
# reads (scripts/lib/result-store.js): the compiler's build configuration and
# its sources (every backend's — `check` is target-independent), this script,
# pool.sh and
# result-store.js, the toolchain, every file of every library a fence's
# `dependencies` can resolve to (each package under the library roots below),
# and the check's own scratch project whole — the fence's text as written, the
# manifest, every file of a named project — with its mode and expectation. Only
# a check that passed is written, and only when its key did not move during
# the run; the harness's own nine fences always run. The store lives in
# `<repo>/.botopinkbuild/cache/results/docs/` (decision 225); `--cold` never
# reads it and writes its passes. The exit line is preceded by
# `result store: <N> fences — <R> run, <S> from store`.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(cd "$here/.." && pwd)"

compiler="$repo/zig-out/bin/botopink"
jobs=""
docs=()
have_docs=0    # `${#docs[@]}` on an empty array is an unbound variable in bash 3.2
list=0
self_test_only=0
cold=0
store_dir=""
given_lib_roots=()
have_lib_roots=0  # as `have_docs`
while [ $# -gt 0 ]; do
    case "$1" in
        --compiler) compiler="$2"; shift 2 ;;
        --compiler=*) compiler="${1#*=}"; shift ;;
        --doc) docs+=("$2"); have_docs=1; shift 2 ;;
        --doc=*) docs+=("${1#*=}"); have_docs=1; shift ;;
        --list) list=1; shift ;;
        --jobs) jobs="$2"; shift 2 ;;
        --jobs=*) jobs="${1#*=}"; shift ;;
        --self-test) self_test_only=1; shift ;;
        --cold) cold=1; shift ;;
        --store-root) store_dir="$2"; shift 2 ;;
        --store-root=*) store_dir="${1#*=}"; shift ;;
        --lib-root) given_lib_roots+=("$2"); have_lib_roots=1; shift 2 ;;
        --lib-root=*) given_lib_roots+=("${1#*=}"); have_lib_roots=1; shift ;;
        -h|--help) sed -n '2,80p' "$0"; exit 0 ;;
        *) echo "check-docs.sh: unknown argument '$1'" >&2; exit 2 ;;
    esac
done
[ "$have_docs" -eq 1 ] || docs=(docs.md README.md)

if [ "$list" -eq 0 ]; then
    [ -x "$compiler" ] || { echo "check-docs.sh: compiler not found or not executable: $compiler" >&2; exit 2; }
    compiler="$(cd "$(dirname "$compiler")" && pwd)/$(basename "$compiler")"
fi
# The library roots a fence's `dependencies` resolve through: the bundled
# `libs/` (std), then the sibling library checkouts — next to this repository
# in the meta workspace (`repository/<lib>`), or under `repository/` when they
# are checked out inside it (CI's layout).
# `--lib-root` replaces the list: every root named, none found.
lib_roots="$repo/libs"
for r in "$repo/.." "$repo/repository"; do
    [ -d "$r" ] && lib_roots="$lib_roots:$(cd "$r" && pwd)"
done
if [ "$have_lib_roots" -eq 1 ]; then
    lib_roots=""
    for r in "${given_lib_roots[@]}"; do
        [ -d "$r" ] || { echo "check-docs.sh: --lib-root: no such directory: $r" >&2; exit 2; }
        lib_roots="${lib_roots:+$lib_roots:}$(cd "$r" && pwd)"
    done
fi
# shellcheck source=lib/pool.sh
. "$here/lib/pool.sh"
[ -n "$jobs" ] || jobs="$(pool_default_jobs)"
pool_check_jobs "$jobs" check-docs.sh

work="$(mktemp -d "${TMPDIR:-/tmp}/bp-check-docs.XXXXXX")"
trap 'rm -rf "$work"' EXIT

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'; NC=$'\033[0m'

# ── extract: one line per fence, `<doc>\t<line>\t<directive>\t<body file>\t<lang>` ──
# Every fence is tracked; a line is printed for a ```botopink fence, and for
# any other fence that a directive precedes (a `project` file of another
# language, or a directive misplaced on a ```text fence — the loop refuses it).
extract() { # <path> <doc label>
    awk -v doc="$2" -v work="$work" '
        /^<!-- docs-check:/ && !infence {
            d = $0
            sub(/^<!-- docs-check:[[:space:]]*/, "", d)
            sub(/[[:space:]]*-->[[:space:]]*$/, "", d)
            pending = d
            next
        }
        /^```[A-Za-z0-9_+-]*[[:space:]]*$/ && !infence {
            infence = 1; start = NR + 1
            lang = $0; sub(/^```/, "", lang); sub(/[[:space:]]*$/, "", lang)
            wanted = (lang == "botopink" || pending != "")
            if (wanted) {
                slug = doc "-" start; gsub(/[^A-Za-z0-9]/, "_", slug)
                body = work "/fence-" slug ".bp"
                printf "" > body
            }
            next
        }
        infence && /^```[[:space:]]*$/ {
            infence = 0
            if (wanted) {
                printf "%s\t%d\t%s\t%s\t%s\n", doc, start, (pending == "" ? "-" : pending), body, (lang == "" ? "-" : lang)
                close(body)
            }
            pending = ""
            next
        }
        infence { if (wanted) print $0 >> body; next }
        # any other line clears a directive that was not followed by a fence
        { if (pending != "" && $0 !~ /^[[:space:]]*$/) pending = "" }
    ' "$1"
}

project() { # <dir>
    mkdir -p "$1/src"
    printf '{ "name": "docs_check", "version": "0.0.1", "src": "src/", "target": "commonJS" }\n' > "$1/botopink.json"
}

strip() { sed "s/$(printf '\033')\[[0-9;]*m//g"; }

first_error() { strip | grep -m1 -iE '^[[:space:]]*error' | sed -E 's/^[[:space:]]*//' | tr '\t' ' '; }

check_project() { # <dir> → prints the first error line on failure
    local out
    out="$(cd "$1" && BOTOPINK_LIB_ROOTS="$lib_roots" with_timeout 300 "$compiler" check 2>&1)" && return 0
    first_error <<<"$out"
    return 1
}

check_reject() { # <dir> <expectation> → prints why on failure
    local out first
    if out="$(cd "$1" && BOTOPINK_LIB_ROOTS="$lib_roots" with_timeout 300 "$compiler" check 2>&1)"; then
        printf 'compiles — the doc claims a refusal the compiler does not make (expected: %s)' "$2"
        return 1
    fi
    first="$(first_error <<<"$out")"
    case "$first" in
        *"$2"*) return 0 ;;
    esac
    printf 'refused, but not with "%s" (got: %s)' "$2" "${first:-no error line}"
    return 1
}

fences=0 ok=0 failed=0

# The `botopink check` runs are deferred and run on the pool (scripts/lib/pool.sh)
# once every fence is extracted. The report is written in fence order to
# `$work/report`, each deferred check as a `\001CHECK <k>` placeholder line, and
# printed after the pool has drained with each placeholder replaced by that
# check's verdict line — so the bytes are the serial run's whatever `--jobs` is.
mkdir -p "$work/checks" "$work/inflight" "$work/labels"
nchecks=0
defer_check() { # <dir> <label> <suffix> <mode> [<expectation>] [<weight>]  — the verdict line is
    #   ok:   "  ✓ <label><suffix>"          fail: "  ✗ <label><NC><suffix>  <why>"
    # <mode> is `compile` (must compile) or `reject` (must be refused with
    # <expectation>); <weight> (default 1) is how many fences the verdict
    # judges — a project's check covers every fence written into it
    nchecks=$((nchecks + 1))
    printf '%s\n%s\n%s\n%s\n%s\n%s\n' "$1" "$2" "$3" "$4" "${5:-}" "${6:-1}" > "$work/checks/$nchecks.job"
    printf '%s\n' "$nchecks" > "$work/labels/$(slug_of "$2")"
    printf '\001CHECK %d\n' "$nchecks"
}
check_job() { # <k> — writes <k>.ok, or <k>.fail holding why
    local dir mode expect why
    dir="$(sed -n 1p "$work/checks/$1.job")"
    mode="$(sed -n 4p "$work/checks/$1.job")"
    expect="$(sed -n 5p "$work/checks/$1.job")"
    if [ "$mode" = reject ]; then
        why="$(check_reject "$dir" "$expect")" && { : > "$work/checks/$1.ok"; return 0; }
    else
        why="$(check_project "$dir")" && { : > "$work/checks/$1.ok"; return 0; }
    fi
    printf '%s' "$why" > "$work/checks/$1.fail"
}
run_checks() {
    [ "$nchecks" -gt 0 ] || return 0
    export -f check_job check_project check_reject first_error strip pool_job pool_admit pool_cpus with_timeout
    export work compiler lib_roots
    # A check answered from the result store already has its `<k>.ok`.
    seq 1 "$nchecks" | while read -r k; do [ -f "$work/checks/$k.ok" ] || echo "$k"; done |
        xargs -r -n 1 -P "$jobs" bash -c 'pool_job "$work/inflight" check_job "$0"'
}

# ── the result store ──────────────────────────────────────────────────────────
store_js="$repo/scripts/lib/result-store.js"
[ -n "$store_dir" ] || store_dir="$repo/.botopinkbuild/cache/results/docs"
store_hits="$work/store-hits"
: > "$store_hits"
# store_spec — one line per deferred check of the docs (the self-test's run
# every time): `checks/<k>.ok`, its mode and expectation, its scratch project.
store_spec() {
    local k dir label mode expect
    for k in $(seq 1 "$nchecks"); do
        label="$(sed -n 2p "$work/checks/$k.job")"
        case "$label" in self-test.md:*) continue ;; esac
        dir="$(sed -n 1p "$work/checks/$k.job")"; mode="$(sed -n 4p "$work/checks/$k.job")"
        expect="$(sed -n 5p "$work/checks/$k.job")"
        printf 'checks/%s.ok\t* %s %s\tproject=%s\n' "$k" "$mode" "$expect" "${dir#"$work/"}"
    done > "$work/store-spec"
}
# store_keys <out> — every check's key, from the files as they are now. The
# global trees are every package the library roots hold — what a fence's
# `dependencies` can name.
store_keys() {
    local trees=() r c
    local IFS=:
    for r in $lib_roots; do
        if [ -f "$r/botopink.json" ]; then trees+=(--global-tree "root:$r=$r"); continue; fi
        for c in "$r"/*/; do
            c="${c%/}"
            [ -f "$c/botopink.json" ] && trees+=(--global-tree "$(basename "$r")/$(basename "$c")=$c")
        done
    done
    unset IFS
    node "$store_js" keys --spec "$work/store-spec" --out "$1" --base "$work" \
        --compiler "$compiler" --global-file "check-docs.sh=$here/check-docs.sh" \
        --global-file "pool.sh=$here/lib/pool.sh" --global-file "result-store.js=$store_js" \
        ${trees[@]+"${trees[@]}"} --global-text "docs" --scratch "$work"
}
# The fences of the checks answered from the store.
store_from_fences() {
    local id k n=0
    while IFS= read -r id; do
        [ -n "$id" ] || continue
        k="${id#checks/}"; k="${k%.ok}"
        n=$((n + $(sed -n 6p "$work/checks/$k.job")))
    done < "$store_hits"
    echo "$n"
}
print_report() { # <report file>
    local l k label suffix weight
    while IFS= read -r l; do
        case "$l" in
            $'\001CHECK '*)
                k="${l#$'\001CHECK '}"
                label="$(sed -n 2p "$work/checks/$k.job")"; suffix="$(sed -n 3p "$work/checks/$k.job")"
                weight="$(sed -n 6p "$work/checks/$k.job")"
                if [ -f "$work/checks/$k.ok" ]; then
                    printf '  %s✓%s %s%s\n' "$GREEN" "$NC" "$label" "$suffix"; ok=$((ok + weight))
                else
                    printf '  %s✗ %s%s%s  %s\n' "$RED" "$label" "$NC" "$suffix" "$(cat "$work/checks/$k.fail" 2>/dev/null)"; failed=$((failed + weight))
                fi ;;
            *) printf '%s\n' "$l" ;;
        esac
    done < "$1"
}

# A named project's state lives in the filesystem, not in an associative array:
# the directory `$work/g-<slug>` is its existence, `.name`/`.origin` inside it
# carry the name and the fence that opened it, and `src/main.bp` is the
# has-an-entry-point flag. Keeps the script bash-3.2 clean (the macOS runner).
slug_of() { printf '%s' "$1" | tr -c 'A-Za-z0-9_.-' '_'; }

# run_doc <path> <label> <report file> <project prefix> — extracts one doc and
# appends its report lines (inline verdicts and deferred placeholders).
run_doc() {
    local path="$1" d="$2" report="$3" gprefix="$4"
    local line directive body lang kind rest dir name
    while IFS=$'\t' read -r d line directive body lang; do
        [ -n "$d" ] || continue
        [ "$directive" = "-" ] && directive=""
        [ "$lang" = "-" ] && lang=""
        kind="${directive%% *}"; rest="${directive#"$kind"}"; rest="${rest# }"
        if [ "$lang" != botopink ] && [ "$kind" != project ]; then
            # a directive on a fence the harness does not compile: the claim is
            # unverifiable there, and the fence must be ```botopink or the
            # directive must go
            printf '  %s✗ %s:%s%s  directive `%s` on a ```%s fence — only `project` may name a fence that is not botopink\n' "$RED" "$d" "$line" "$NC" "$directive" "$lang"
            failed=$((failed + 1)); fences=$((fences + 1)); continue
        fi
        fences=$((fences + 1))
        if [ "$list" -eq 1 ]; then
            printf '%s:%s\t%s\n' "$d" "$line" "${directive:-module}"
            continue
        fi
        case "$kind" in
            "")
                dir="$work/p-$fences"; project "$dir"; cp "$body" "$dir/src/main.bp"
                defer_check "$dir" "$d:$line" "" compile ;;
            body)
                dir="$work/p-$fences"; project "$dir"
                { echo "fn main() {"; sed -E 's/^/    /' "$body"; echo "}"; } > "$dir/src/main.bp"
                defer_check "$dir" "$d:$line" " (body)" compile ;;
            reject)
                local wrap="" expect="$rest"
                case "$expect" in
                    body|body\ *) wrap=body; expect="${expect#body}"; expect="${expect# }" ;;
                esac
                if [ -z "$expect" ]; then
                    printf '  %s✗ %s:%s%s  reject needs an expectation (the error id or message the refusal must carry)\n' "$RED" "$d" "$line" "$NC"; failed=$((failed + 1)); continue
                fi
                dir="$work/p-$fences"; project "$dir"
                if [ -n "$wrap" ]; then
                    { echo "fn main() {"; sed -E 's/^/    /' "$body"; echo "}"; } > "$dir/src/main.bp"
                else
                    cp "$body" "$dir/src/main.bp"
                fi
                defer_check "$dir" "$d:$line" " (reject${wrap:+ body}: $expect)" reject "$expect" ;;
            project)
                name="${rest%% *}"; path="${rest#"$name"}"; path="${path# }"
                if [ -z "$name" ] || [ -z "$path" ]; then
                    printf '  %s✗ %s:%s%s  project needs <name> <path>\n' "$RED" "$d" "$line" "$NC"; failed=$((failed + 1)); continue
                fi
                dir="$work/$gprefix-$(slug_of "$name")"
                if [ ! -d "$dir" ]; then
                    project "$dir"
                    printf '%s\n' "$name" > "$dir/.name"
                    printf '%s\n' "$d:$line" > "$dir/.origin"
                    : > "$dir/.files"
                fi
                echo "$path" >> "$dir/.files"    # one line per fence: the check's weight
                mkdir -p "$dir/$(dirname "$path")"; cp "$body" "$dir/$path"
                printf '  %s·%s %s:%s → %s/%s\n' "$YELLOW" "$NC" "$d" "$line" "$name" "$path" ;;
            *)
                printf '  %s✗ %s:%s%s  unknown directive: %s\n' "$RED" "$d" "$line" "$NC" "$directive"; failed=$((failed + 1)) ;;
        esac
    done < <(extract "$path" "$d") >> "$report"
}

# close_projects <report file> <project prefix> — every named project gets its
# one deferred check, whose verdict counts for every fence written into it, or
# the refusal for a project with no entry point (every fence of it failed).
close_projects() {
    local dir name origin nfiles
    for dir in "$work"/"$2"-*; do
        [ -d "$dir" ] || continue    # no named project in these docs
        name="$(cat "$dir/.name")"; origin="$(cat "$dir/.origin")"
        nfiles="$(wc -l < "$dir/.files" | tr -d ' ')"
        if [ ! -f "$dir/src/main.bp" ]; then
            printf '  %s✗ project %s%s  no fence writes src/main.bp (first at %s)\n' "$RED" "$name" "$NC" "$origin"
            failed=$((failed + nfiles)); continue
        fi
        defer_check "$dir" "project $name" " ($origin)" compile "" "$nfiles"
    done >> "$1"
}

# ── the harness's own contract ────────────────────────────────────────────────
# Nine fences with known verdicts, judged before any doc: a harness whose
# `reject` passes a fence that compiles would let the docs claim any refusal.
self_test_doc="$work/self-test.md"
self_test_expected="fail fail ok ok fail fail ok fail fail"
write_self_test() {
    cat > "$self_test_doc" <<'EOF'
# check-docs.sh self-test — every fence's verdict is known

1. a `reject` fence that compiles must fail: the doc would claim a refusal the compiler does not make

<!-- docs-check: reject iter-await -->
```botopink
fn ok() -> i32 { return 1; }
```

2. a `reject` fence refused with another first diagnostic must fail

<!-- docs-check: reject iter-await -->
```botopink
fn g() -> @Iterator<i32> {
    throw "x";
}
```

3. a `reject` fence refused with the named diagnostic passes

<!-- docs-check: reject effect-try-without-fallible-channel -->
```botopink
fn g() -> @Iterator<i32> {
    throw "x";
}
```

4. `reject body` wraps statements in `fn main` first

<!-- docs-check: reject body unbound variable 'nope' -->
```botopink
nope();
```

5. there is no `skip`: the directive is unknown and fails

<!-- docs-check: skip a table, not a module -->
```botopink
a + b, a - b
```

6. a module that does not compile fails

```botopink
fn g() -> @Iterator<i32> {
    throw "x";
}
```

7. a module that compiles passes

```botopink
fn ok() -> i32 { return 1; }
```

8. a `reject` with no expectation fails

<!-- docs-check: reject -->
```botopink
fn ok() -> i32 { return 1; }
```

9. a directive on a fence that is not botopink fails

<!-- docs-check: body -->
```text
a + b
```
EOF
}
# judge_self_test — prints one line per verdict that differs; returns 1 if any
judge_self_test() {
    local lines i=0 line want got k bad=0
    lines="$(extract "$self_test_doc" self-test.md | cut -f2)"
    for want in $self_test_expected; do
        i=$((i + 1))
        line="$(printf '%s\n' "$lines" | sed -n "${i}p")"
        if [ -f "$work/labels/$(slug_of "self-test.md:$line")" ]; then
            k="$(cat "$work/labels/$(slug_of "self-test.md:$line")")"
            if [ -f "$work/checks/$k.ok" ]; then got=ok; else got=fail; fi
        elif grep -qF "✗ self-test.md:$line$NC" "$work/report-self"; then
            got=fail
        else
            got=missing
        fi
        if [ "$got" != "$want" ]; then
            printf '  %s✗ self-test.md:%s%s  case %d: expected %s, got %s\n' "$RED" "$line" "$NC" "$i" "$want" "$got"
            bad=1
        fi
    done
    return $bad
}

if [ "$list" -eq 0 ]; then
    write_self_test
    : > "$work/report-self"
    saved_fences=$fences saved_failed=$failed
    run_doc "$self_test_doc" self-test.md "$work/report-self" s
    close_projects "$work/report-self" s
    fences=$saved_fences failed=$saved_failed
fi

: > "$work/report"
if [ "$self_test_only" -eq 0 ]; then
    for doc in "${docs[@]}"; do
        case "$doc" in /*) path="$doc" ;; *) path="$repo/$doc" ;; esac
        [ -f "$path" ] || { printf '%s✗ %s: no such file%s\n' "$RED" "$doc" "$NC" >> "$work/report"; failed=$((failed + 1)); continue; }
        run_doc "$path" "$doc" "$work/report" g
    done
fi

if [ "$list" -eq 1 ]; then cat "$work/report"; exit 0; fi

close_projects "$work/report" g

if [ "$self_test_only" -eq 0 ]; then
    store_spec
    store_keys "$work/keys-before" || { echo "check-docs.sh: the result store's keys could not be computed" >&2; exit 2; }
fi
if [ "$cold" -eq 0 ] && [ "$self_test_only" -eq 0 ]; then
    node "$store_js" lookup --store "$store_dir" --keys "$work/keys-before" --work "$work" --out "$store_hits" ||
        { echo "check-docs.sh: the result store could not be read" >&2; exit 2; }
fi

run_checks

store_note=""
[ "$cold" -eq 0 ] || store_note=" (--cold: nothing read from the store)"
if [ "$self_test_only" -eq 0 ]; then
    store_keys "$work/keys-after" || { echo "check-docs.sh: the result store's keys could not be computed" >&2; exit 2; }
    read -r store_written store_moved < <(node "$store_js" save --store "$store_dir" --before "$work/keys-before" \
        --after "$work/keys-after" --work "$work" --hits "$store_hits" --pass exists) ||
        { echo "check-docs.sh: the result store could not be written" >&2; exit 2; }
    [ "${store_moved:-0}" -eq 0 ] || store_note="$store_note ($store_moved not written: their inputs moved during the run)"
fi

if judge_self_test; then
    printf 'self-test: 9 fences — 9 verdicts as expected\n'
else
    printf '%sself-test: the harness does not judge its own fences as documented — the docs are not judged%s\n' "$RED" "$NC"
    exit 1
fi
[ "$self_test_only" -eq 0 ] || exit 0

print_report "$work/report"

# What was executed and what was answered from a stored pass; `scripts/gate.sh`
# holds run + from store to the plan. A fence judged without the compiler (an
# unknown directive, a project with no entry point) counts as run.
awk -F '\t' '
    $2 == "-" { if (!($3 in n)) order[++k] = $3; n[$3]++ }
    END { for (i = 1; i <= k; i++) printf "result store: %d check%s never stored — %s\n", n[order[i]], (n[order[i]] == 1 ? "" : "s"), order[i] }
' "$work/keys-before"
store_from="$(store_from_fences)"
printf '\nresult store: %d fences — %d run, %d from store%s\n' "$fences" "$((fences - store_from))" "$store_from" "$store_note"
# `0 skipped` is a constant: no directive skips a fence (decision gate-e), and
# the gate's exit line keeps the column so "skipped" stays visibly zero.
printf '\ndocs: %d fences — %d checked, 0 skipped, %d failed\n' "$fences" "$ok" "$failed"
[ "$failed" -eq 0 ] || exit 1
