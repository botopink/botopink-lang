#!/usr/bin/env bash
# check-docs.sh — every `botopink` fence in the user docs is compiled
# (`zig build test-docs`).
#
# Usage:
#   scripts/check-docs.sh [--compiler <botopink>] [--doc <file>]… [--list] [--jobs <n>]
#
#   --compiler  the `botopink` binary; default <repo>/zig-out/bin/botopink
#   --doc       a markdown file to check; repeatable, default `docs.md README.md`
#   --list      print every fence with its directive and exit (compiles nothing)
#   --jobs      parallel `botopink check` runs; default one per CPU, bounded by
#               memory (scripts/lib/pool.sh). The report is printed in fence
#               order whatever the count, so `--jobs 1` prints the same bytes
#
# A fence is ```botopink. What the checker does with it is decided by an HTML
# comment on the line just above the fence (invisible in rendered markdown, and
# the fence keeps its `botopink` highlighting):
#
#   (no comment)                     a whole module → written as src/main.bp
#   <!-- docs-check: body -->        statements → wrapped in `fn main() { … }`
#   <!-- docs-check: project <name> <path> -->
#                                    one file of a multi-file project; every
#                                    fence with the same <name> is written at
#                                    its <path> and the project is checked once
#                                    (one of them must be src/main.bp)
#   <!-- docs-check: skip <reason> --> a fragment that is not a module (a literal
#                                    list, an operator table): never compiled.
#                                    The reason is required and is printed.
#
# Each module or project is checked with `botopink check` in a scratch project
# (`{ "target": "commonJS" }`; `check` is target-independent). A fence that
# fails, an unknown directive, a `skip` with no reason and a project with no
# `src/main.bp` all fail the run.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(cd "$here/.." && pwd)"

compiler="$repo/zig-out/bin/botopink"
jobs=""
docs=()
have_docs=0    # `${#docs[@]}` on an empty array is an unbound variable in bash 3.2
list=0
while [ $# -gt 0 ]; do
    case "$1" in
        --compiler) compiler="$2"; shift 2 ;;
        --compiler=*) compiler="${1#*=}"; shift ;;
        --doc) docs+=("$2"); have_docs=1; shift 2 ;;
        --doc=*) docs+=("${1#*=}"); have_docs=1; shift ;;
        --list) list=1; shift ;;
        --jobs) jobs="$2"; shift 2 ;;
        --jobs=*) jobs="${1#*=}"; shift ;;
        -h|--help) sed -n '2,33p' "$0"; exit 0 ;;
        *) echo "check-docs.sh: unknown argument '$1'" >&2; exit 2 ;;
    esac
done
[ "$have_docs" -eq 1 ] || docs=(docs.md README.md)

if [ "$list" -eq 0 ]; then
    [ -x "$compiler" ] || { echo "check-docs.sh: compiler not found or not executable: $compiler" >&2; exit 2; }
    compiler="$(cd "$(dirname "$compiler")" && pwd)/$(basename "$compiler")"
fi
lib_root="$repo/libs"
# shellcheck source=lib/pool.sh
. "$here/lib/pool.sh"
[ -n "$jobs" ] || jobs="$(pool_default_jobs)"
pool_check_jobs "$jobs" check-docs.sh

work="$(mktemp -d "${TMPDIR:-/tmp}/bp-check-docs.XXXXXX")"
trap 'rm -rf "$work"' EXIT

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'; NC=$'\033[0m'

# ── extract: one line per fence, `<doc>\t<line>\t<directive>\t<body file>` ────
extract() { # <doc>
    awk -v doc="$1" -v work="$work" '
        /^<!-- docs-check:/ {
            d = $0
            sub(/^<!-- docs-check:[[:space:]]*/, "", d)
            sub(/[[:space:]]*-->[[:space:]]*$/, "", d)
            pending = d
            next
        }
        /^```botopink[[:space:]]*$/ {
            infence = 1; start = NR + 1
            slug = doc "-" start; gsub(/[^A-Za-z0-9]/, "_", slug)
            body = work "/fence-" slug ".bp"
            printf "" > body
            next
        }
        infence && /^```[[:space:]]*$/ {
            infence = 0
            printf "%s\t%d\t%s\t%s\n", doc, start, (pending == "" ? "-" : pending), body
            pending = ""
            close(body)
            next
        }
        infence { print $0 >> body; next }
        # any other line clears a directive that was not followed by a fence
        { if (pending != "" && $0 !~ /^[[:space:]]*$/) pending = "" }
    ' "$1"
}

project() { # <dir>
    mkdir -p "$1/src"
    printf '{ "name": "docs_check", "version": "0.0.1", "src": "src/", "target": "commonJS" }\n' > "$1/botopink.json"
}

strip() { sed -r 's/\x1b\[[0-9;]*m//g'; }

check_project() { # <dir> → prints the first error line on failure
    local out
    out="$(cd "$1" && BOTOPINK_LIB_ROOTS="$lib_root" timeout 300 "$compiler" check 2>&1)" && return 0
    strip <<<"$out" | grep -m1 -iE '^[[:space:]]*error' | sed -r 's/^[[:space:]]*//' | tr '\t' ' '
    return 1
}

fences=0 ok=0 skipped=0 failed=0

# The `botopink check` runs are deferred and run on the pool (scripts/lib/pool.sh)
# once every fence is extracted. The report is written in fence order to
# `$work/report`, each deferred check as a `\001CHECK <k>` placeholder line, and
# printed after the pool has drained with each placeholder replaced by that
# check's verdict line — so the bytes are the serial run's whatever `--jobs` is.
mkdir -p "$work/checks" "$work/inflight"
nchecks=0
defer_check() { # <dir> <label> <suffix>  — the verdict line is
    #   ok:   "  ✓ <label><suffix>"          fail: "  ✗ <label><NC><suffix>  <why>"
    nchecks=$((nchecks + 1))
    printf '%s\n%s\n%s\n' "$1" "$2" "$3" > "$work/checks/$nchecks.job"
    printf '\001CHECK %d\n' "$nchecks"
}
check_job() { # <k> — writes <k>.ok, or <k>.fail holding the first error line
    local dir
    dir="$(sed -n 1p "$work/checks/$1.job")"
    if why="$(check_project "$dir")"; then
        : > "$work/checks/$1.ok"
    else
        printf '%s' "$why" > "$work/checks/$1.fail"
    fi
}
run_checks() {
    [ "$nchecks" -gt 0 ] || return 0
    export -f check_job check_project strip pool_job pool_admit pool_cpus
    export work compiler lib_root
    seq 1 "$nchecks" | xargs -n 1 -P "$jobs" bash -c 'pool_job "$work/inflight" check_job "$0"'
}
print_report() {
    local l k label suffix
    while IFS= read -r l; do
        case "$l" in
            $'\001CHECK '*)
                k="${l#$'\001CHECK '}"
                label="$(sed -n 2p "$work/checks/$k.job")"; suffix="$(sed -n 3p "$work/checks/$k.job")"
                if [ -f "$work/checks/$k.ok" ]; then
                    printf '  %s✓%s %s%s\n' "$GREEN" "$NC" "$label" "$suffix"; ok=$((ok + 1))
                else
                    printf '  %s✗ %s%s%s  %s\n' "$RED" "$label" "$NC" "$suffix" "$(cat "$work/checks/$k.fail" 2>/dev/null)"; failed=$((failed + 1))
                fi ;;
            *) printf '%s\n' "$l" ;;
        esac
    done < "$work/report"
}

# A named project's state lives in the filesystem, not in an associative array:
# the directory `$work/g-<slug>` is its existence, `.name`/`.origin` inside it
# carry the name and the fence that opened it, and `src/main.bp` is the
# has-an-entry-point flag. Keeps the script bash-3.2 clean (the macOS runner).
slug_of() { printf '%s' "$1" | tr -c 'A-Za-z0-9_.-' '_'; }

for doc in "${docs[@]}"; do
    [ -f "$repo/$doc" ] || { echo "${RED}✗ $doc: no such file${NC}" >&2; failed=$((failed + 1)); continue; }
    while IFS=$'\t' read -r d line directive body; do
        [ -n "$d" ] || continue
        fences=$((fences + 1))
        [ "$directive" = "-" ] && directive=""
        kind="${directive%% *}"; rest="${directive#"$kind"}"; rest="${rest# }"
        if [ "$list" -eq 1 ]; then
            printf '%s:%s\t%s\n' "$d" "$line" "${directive:-module}"
            continue
        fi
        case "$kind" in
            "")
                dir="$work/p-$fences"; project "$dir"; cp "$body" "$dir/src/main.bp"
                defer_check "$dir" "$d:$line" "" ;;
            body)
                dir="$work/p-$fences"; project "$dir"
                { echo "fn main() {"; sed -r 's/^/    /' "$body"; echo "}"; } > "$dir/src/main.bp"
                defer_check "$dir" "$d:$line" " (body)" ;;
            project)
                name="${rest%% *}"; path="${rest#"$name"}"; path="${path# }"
                if [ -z "$name" ] || [ -z "$path" ]; then
                    printf '  %s✗ %s:%s%s  project needs <name> <path>\n' "$RED" "$d" "$line" "$NC"; failed=$((failed + 1)); continue
                fi
                dir="$work/g-$(slug_of "$name")"
                if [ ! -d "$dir" ]; then
                    project "$dir"
                    printf '%s\n' "$name" > "$dir/.name"
                    printf '%s\n' "$d:$line" > "$dir/.origin"
                fi
                mkdir -p "$dir/$(dirname "$path")"; cp "$body" "$dir/$path"
                printf '  %s·%s %s:%s → %s/%s\n' "$YELLOW" "$NC" "$d" "$line" "$name" "$path" ;;
            skip)
                if [ -z "$rest" ]; then
                    printf '  %s✗ %s:%s%s  skip needs a reason\n' "$RED" "$d" "$line" "$NC"; failed=$((failed + 1))
                else
                    printf '  %s—%s %s:%s  skipped: %s\n' "$YELLOW" "$NC" "$d" "$line" "$rest"; skipped=$((skipped + 1))
                fi ;;
            *)
                printf '  %s✗ %s:%s%s  unknown directive: %s\n' "$RED" "$d" "$line" "$NC" "$directive"; failed=$((failed + 1)) ;;
        esac
    done < <(extract "$repo/$doc" | sed "s#^$repo/##")
done > "$work/report"

if [ "$list" -eq 1 ]; then cat "$work/report"; exit 0; fi

for dir in "$work"/g-*; do
    [ -d "$dir" ] || continue    # no named project in these docs
    name="$(cat "$dir/.name")"; origin="$(cat "$dir/.origin")"
    if [ ! -f "$dir/src/main.bp" ]; then
        printf '  %s✗ project %s%s  no fence writes src/main.bp (first at %s)\n' "$RED" "$name" "$NC" "$origin"
        failed=$((failed + 1)); continue
    fi
    defer_check "$dir" "project $name" " ($origin)"
done >> "$work/report"

run_checks
print_report

printf '\ndocs: %d fences — %d checked, %d skipped, %d failed\n' "$fences" "$ok" "$skipped" "$failed"
[ "$failed" -eq 0 ] || exit 1
