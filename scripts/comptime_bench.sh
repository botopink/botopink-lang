#!/usr/bin/env bash
# comptime_bench.sh — what the comptime path costs, on this machine.
#
# Every budget of `specs/1.0.12-beta/01-compiler/14-comptime-on-beam/` (and the
# table of `18-comptime-runtimes` step 3) is a time measurement, so the
# measurement lives here rather than in the document. Two instruments:
#
#   E-1  wall clock of one `botopink build`, best of `--repeat` runs, over a
#        generated project with N call sites of ONE template whose literals are
#        all distinct (so the memo cache in `comptime/infer.zig` never hits).
#   E-2  the in-compiler split — where an evaluation's time goes, stage by
#        stage — from one more build of the largest N (and of each `--project`)
#        run with `BOTOPINK_COMPTIME_STAGES=<file>`
#        (`modules/compiler-core/src/comptime/runtime/stages.zig`): the
#        compiler appends `<stage> TAB <ns>` per timed stage, and the table
#        sums them. Modules travel to the runtime in-frame (BEAM, cmd 4) or
#        in-process (wasm3), so there is nothing on disk to time separately.
#
# Nothing is written inside a repository: every project is generated into a
# `mktemp -d` and deleted unless `--keep` is given.
#
# Usage:
#   scripts/comptime_bench.sh [--n 0,1,10,50,100,200] [--repeat 5]
#                             [--project <dir>] [--target commonJS]
#                             [--keep] [--no-build]
#
#   --n LIST      call-site counts for the generated project (default 0,10,200;
#                 `--n ''` skips the generated project entirely)
#   --repeat R    builds per N; the minimum is reported (default 3)
#   --project D   also copy D into a scratch tree, build it, and report its
#                 split. Repeatable. A `path:` dependency of D is
#                 copied beside it, so a git dependency must already be
#                 vendored there; a workspace member (`{ "workspace": true }`)
#                 is built inside a copy of its enclosing workspace.
#   --target T    build target (default commonJS — the wat runtime; `erlang`
#                 and `beam` evaluate on the BEAM runtime, decision 84)
#   --keep        leave the scratch tree in place and print its path
#   --no-build    do not run `zig build` first
#
# `BOTOPINK_LIB_ROOTS` is inherited, so a project whose libraries live in a
# sibling checkout is measured by pointing it at that tree:
#
#   BOTOPINK_LIB_ROOTS=../../repository scripts/comptime_bench.sh --n '' \
#       --project ../../repository/erika/examples/erika-linq
#
# Exit 0 when every build succeeded, 1 otherwise. `erl` (OTP 28) is required
# for the `erlang` and `beam` targets only.
set -euo pipefail

ns="0,10,200"
repeat=3
target="commonJS"
keep=0
do_build=1
projects=()

while [ $# -gt 0 ]; do
    case "$1" in
        --n) ns="${2-}"; shift 2 ;;
        --repeat) repeat="${2-}"; shift 2 ;;
        --target) target="${2-}"; shift 2 ;;
        --project) projects+=("${2-}"); shift 2 ;;
        --keep) keep=1; shift ;;
        --no-build) do_build=0; shift ;;
        -h|--help) sed -n '2,45p' "$0"; exit 0 ;;
        *) echo "comptime_bench: unknown argument '$1'" >&2; exit 1 ;;
    esac
done

root="$(git rev-parse --show-toplevel)"
cd "$root"
botopink="$root/zig-out/bin/botopink"

if [ "$do_build" -eq 1 ]; then
    zig build >/dev/null || { echo "comptime_bench: zig build failed" >&2; exit 1; }
fi
[ -x "$botopink" ] || { echo "comptime_bench: $botopink is not built (drop --no-build)" >&2; exit 1; }

scratch="$(mktemp -d "${TMPDIR:-/tmp}/comptime_bench.XXXXXXXX")"
if [ "$keep" -eq 1 ]; then
    printf 'scratch: %s\n\n' "$scratch"
else
    trap 'rm -rf "$scratch"' EXIT
fi

# ── E-2: the in-compiler split ────────────────────────────────────────────────
#
# stage_split <label> <project-dir>: one more build of the project (not one of the
# timed ones — writing the stage lines costs a few microseconds each) with the
# stage clock on, then one row per stage: how many times it ran, its total, and
# its share of one evaluation (total / evaluations, where an evaluation is one
# `module` line — a memo hit in `infer.zig` evaluates nothing). Stages that did
# not run (`frame` on the wat runtime, `instance`/`run` on the BEAM one) are
# absent. The rows' order is the order an evaluation meets them.
stage_split() {
    local label="$1" dir="$2"
    local stages_file="$scratch/stages.$(basename "$dir")"
    rm -rf "$dir/.botopinkbuild" "$dir/out" "$stages_file"
    (cd "$dir" && BOTOPINK_COMPTIME_STAGES="$stages_file" "$botopink" build --target "$target" >/dev/null 2>&1) \
        || { printf '\nsplit — %s: the build failed\n' "$label"; return 1; }
    if [ ! -s "$stages_file" ]; then
        printf '\nsplit — %s: no comptime evaluation ran\n' "$label"
        return 0
    fi
    printf '\nsplit — %s, target %s (one build, stage clock on)\n\n' "$label" "$target"
    awk -F '\t' '
        { total[$1] += $2; count[$1]++ }
        END {
            evals = count["module"] + 0
            n = split("memo_key module encode lower instance run frame listing outcome", order, " ")
            printf "  %-10s %8s %12s %12s\n", "stage", "runs", "total (ms)", "ms/eval"
            sum = 0
            for (i = 1; i <= n; i++) {
                s = order[i]
                if (!(s in count)) continue
                per = (evals > 0 ? total[s] / evals / 1e6 : 0)
                printf "  %-10s %8d %12.1f %12.3f\n", s, count[s], total[s] / 1e6, per
                sum += total[s]
            }
            printf "  %-10s %8d %12.1f %12.3f\n", "TOTAL", evals, sum / 1e6, (evals > 0 ? sum / evals / 1e6 : 0)
        }' "$stages_file"
}

# ── E-1: the generated N-call-site project ────────────────────────────────────

gen_project() {
    local dir="$1" n="$2"
    mkdir -p "$dir/src"
    cat > "$dir/botopink.json" <<EOF
{ "name": "bench", "version": "0.0.1", "target": "$target", "entry": "main.bp" }
EOF
    {
        cat <<'BP'
pub fn conf<T>(comptime q: @Expr<string>) -> @Expr<T> {
    val t = q.text();
    val host = "0.0.0.0";
    val port = 8000 + t.length;
    val server = #(host, port);
    val debug = true;
    return @expr(#(server, debug));
}

BP
        for ((i = 0; i < n; i++)); do
            printf 'val c%d = conf "cfg-%d";\n' "$i" "$i"
        done
        printf '\nfn main() {\n'
        [ "$n" -gt 0 ] && printf '    @println(c0);\n'
        printf '}\n'
    } > "$dir/src/main.bp"
}

# build_min <dir>: the minimum wall clock, in milliseconds, of `--repeat` builds.
build_min() {
    local dir="$1" best="" t0 t1 ms
    for ((r = 0; r < repeat; r++)); do
        rm -rf "$dir/.botopinkbuild" "$dir/out"
        t0=$(date +%s%N)
        (cd "$dir" && "$botopink" build --target "$target" >/dev/null 2>&1) || { echo "FAILED"; return 1; }
        t1=$(date +%s%N)
        ms=$(( (t1 - t0) / 1000000 ))
        if [ -z "$best" ] || [ "$ms" -lt "$best" ]; then best="$ms"; fi
    done
    echo "$best"
}

status=0
if [ -n "$ns" ]; then
    printf 'generated project — one template, N distinct call sites, target %s (min of %d builds)\n\n' \
           "$target" "$repeat"
    printf '  %5s %14s %12s\n' "N" "build (ms)" "ms/eval"
    prev_n=""; prev_ms=""; last_dir=""; last_n=""
    IFS=',' read -r -a n_list <<< "$ns"
    for n in "${n_list[@]}"; do
        n="$(echo "$n" | tr -d '[:space:]')"
        [ -n "$n" ] || continue
        dir="$scratch/gen-$n"
        gen_project "$dir" "$n"
        ms="$(build_min "$dir")" || { status=1; printf '  %5s %14s\n' "$n" "BUILD FAILED"; continue; }
        slope="—"
        if [ -n "$prev_n" ] && [ "$n" -gt "$prev_n" ]; then
            slope=$(awk -v a="$prev_ms" -v b="$ms" -v c="$prev_n" -v d="$n" 'BEGIN {printf "%.1f", (b - a) / (d - c)}')
        fi
        printf '  %5s %14s %12s\n' "$n" "$ms" "$slope"
        prev_n="$n"; prev_ms="$ms"; last_dir="$dir"; last_n="$n"
    done
    if [ -n "$last_dir" ]; then
        stage_split "generated N=$last_n" "$last_dir" || status=1
    fi
fi

# ── a real project ────────────────────────────────────────────────────────────
#
# Copied out of its repository first: a build writes `.botopinkbuild/` and `out/`,
# and this script writes nothing inside a checkout.

for p in ${projects+"${projects[@]}"}; do
    [ -d "$p" ] || { echo "comptime_bench: --project $p is not a directory" >&2; status=1; continue; }
    name="$(basename "$p")"
    dir="$scratch/$name"
    # A workspace member (`{ "workspace": true }` dependencies) resolves them
    # from the enclosing workspace, so the whole workspace is copied and the
    # member is built inside the copy. A member with no enclosing workspace is
    # refused here, not left to fail inside the timed build.
    if grep -q '"workspace"[[:space:]]*:[[:space:]]*true' "$p/botopink.json" 2>/dev/null; then
        ws="$(cd "$p" && pwd)"; member=""
        while [ "$ws" != "/" ]; do
            member="$(basename "$ws")${member:+/$member}"
            ws="$(dirname "$ws")"
            grep -q '"workspaces"' "$ws/botopink.json" 2>/dev/null && break
        done
        if [ "$ws" = "/" ]; then
            echo "comptime_bench: --project $p has a { \"workspace\": true } dependency but no enclosing botopink.json declares \"workspaces\"" >&2
            status=1; continue
        fi
        mkdir -p "$scratch/ws-$name"
        tar -C "$ws" --exclude=.git --exclude=.botopinkbuild --exclude=out -cf - . | tar -C "$scratch/ws-$name" -xf -
        dir="$scratch/ws-$name/$member"
    else
        cp -r "$p" "$dir"
    fi
    rm -rf "$dir/.botopinkbuild" "$dir/out"
    # A `path:` dependency pointed at a sibling of the original is copied too,
    # so the copy resolves without reaching back into the repository.
    while IFS= read -r rel; do
        [ -n "$rel" ] || continue
        src="$p/$rel"
        [ -d "$src" ] || continue
        mkdir -p "$(dirname "$dir/$rel")"
        [ -e "$dir/$rel" ] || cp -r "$src" "$dir/$rel"
    done < <(grep -o '"path"[[:space:]]*:[[:space:]]*"[^"]*"' "$p/botopink.json" 2>/dev/null \
             | sed 's/.*"\([^"]*\)"$/\1/')
    printf '\nproject %s — %s (min of %d builds)\n\n' "$name" "$p" "$repeat"
    ms="$(build_min "$dir")" || { status=1; printf '  build FAILED\n'; continue; }
    printf '  build (ms): %s\n' "$ms"
    stage_split "$name" "$dir" || status=1
done

exit "$status"
