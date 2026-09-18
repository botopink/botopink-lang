#!/usr/bin/env bash
# comptime_bench.sh — what the comptime path costs, on this machine.
#
# Every claim of `specs/1.0.5-beta/14-comptime-on-beam/` is a time measurement,
# so the measurement lives here rather than in the document. Two instruments,
# the ones `evidence.md` calls E-1 and E-2:
#
#   E-1  wall clock of one `botopink build`, best of `--repeat` runs, over a
#        generated project with N call sites of ONE template whose literals are
#        all distinct (so the memo cache in `comptime/infer.zig` never hits).
#   E-2  the in-node split — `compile:file` / `code:load_binary` / `main()` —
#        measured inside a single `erl` over the modules a build left behind in
#        `.botopinkbuild/tmp/{template,decorator}`.
#
# Nothing is written inside a repository: every project is generated into a
# `mktemp -d` and deleted unless `--keep` is given.
#
# Usage:
#   scripts/comptime_bench.sh [--n 0,1,10,50,100,200] [--repeat 5]
#                             [--project <dir>] [--target commonJS]
#                             [--reps 50] [--keep] [--no-build]
#
#   --n LIST      call-site counts for the generated project (default 0,10,200;
#                 `--n ''` skips the generated project entirely)
#   --repeat R    builds per N; the minimum is reported (default 3)
#   --project D   also copy D into a scratch tree, build it, and report its
#                 in-node split. Repeatable. A `path:` dependency of D is
#                 rewritten to the copy, so a git dependency must already be
#                 vendored beside it.
#   --target T    build target (default commonJS — a JavaScript build pays the
#                 whole comptime cost, which is the point)
#   --reps N      in-node repetitions per module (default 20, after a warm-up)
#   --keep        leave the scratch tree in place and print its path
#   --no-build    do not run `zig build` first
#
# `BOTOPINK_LIB_ROOTS` is inherited, so a project whose libraries live in a
# sibling checkout is measured by pointing it at that tree:
#
#   BOTOPINK_LIB_ROOTS=../../repository scripts/comptime_bench.sh --n '' \
#       --project ../../repository/erika/examples/erika-linq
#
# Exit 0 when every build succeeded, 1 otherwise. `erl` and `erlc` are required
# for the in-node split; without them the E-1 table is still printed.
set -euo pipefail

ns="0,10,200"
repeat=3
reps=20
target="commonJS"
keep=0
do_build=1
projects=()

while [ $# -gt 0 ]; do
    case "$1" in
        --n) ns="${2-}"; shift 2 ;;
        --repeat) repeat="${2-}"; shift 2 ;;
        --reps) reps="${2-}"; shift 2 ;;
        --target) target="${2-}"; shift 2 ;;
        --project) projects+=("${2-}"); shift 2 ;;
        --keep) keep=1; shift ;;
        --no-build) do_build=0; shift ;;
        -h|--help) sed -n '2,38p' "$0"; exit 0 ;;
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

have_erl=1
command -v erl >/dev/null 2>&1 || have_erl=0

# ── the in-node harness (E-2) ─────────────────────────────────────────────────
#
# One `erl`, one pass per module: compile it once to warm the code server, then
# `--reps` timed rounds of `compile:file/2`, `code:load_binary/3` and, when the
# module exports it, `main/0`. A module that takes its data as an argument
# exports `main/1` instead; its body cannot be run without that argument, so the
# run column reads `-` and the compile columns — which are what this front moves
# — stay comparable across every step.
bench_erl="$scratch/bp_comptime_bench.erl"
cat > "$bench_erl" <<'ERL'
-module(bp_comptime_bench).
-export([main/1]).

main([RepsS | Files]) ->
    Reps = list_to_integer(RepsS),
    Rows = [row(F, Reps) || F <- Files],
    lists:foreach(fun print_row/1, Rows),
    print_total(Rows),
    halt(0);
main(_) ->
    halt(2).

row(File, Reps) ->
    case compile:file(File, [binary, return]) of
        {ok, Mod, Beam} -> row(File, Reps, Mod, Beam);
        {ok, Mod, Beam, _W} -> row(File, Reps, Mod, Beam);
        {error, _, _} -> {File, error, 0, 0.0, 0.0, none, 0}
    end.

row(File, Reps, Mod, Beam) ->
    {module, _} = code:load_binary(Mod, "", Beam),
    Lines = lines(File),
    Compile = avg(fun() -> compile:file(File, [binary, return]) end, Reps),
    %% Before the load round: `code:load_binary/3` repeated leaves old versions
    %% for the code server to reap, and the first calls after it are charged for
    %% that rather than for the body.
    Run = case lists:member({main, 0}, Mod:module_info(exports)) of
        true -> {ok, avg(fun() -> catch Mod:main() end, Reps)};
        false -> none
    end,
    Load = avg(fun() -> code:load_binary(Mod, "", Beam) end, Reps),
    {File, Lines, byte_size(Beam), Compile, Load, Run, Reps}.

%% Milliseconds per call. One untimed call first: the first `Mod:main()` of a
%% run loads whatever the body reaches (`json`, `string`, …) and would otherwise
%% be charged to whichever module happens to be measured first.
avg(F, Reps) ->
    _ = F(),
    T0 = erlang:monotonic_time(microsecond),
    lists:foreach(fun(_) -> F() end, lists:seq(1, Reps)),
    T1 = erlang:monotonic_time(microsecond),
    (T1 - T0) / (Reps * 1000).

lines(File) ->
    case file:read_file(File) of
        {ok, Bin} -> length(binary:split(Bin, <<"\n">>, [global]));
        _ -> 0
    end.

print_row({File, error, _, _, _, _, _}) ->
    io:format("  ~-44s  ~s~n", [filename:basename(File), "did not compile"]);
print_row({File, Lines, BeamSize, Compile, Load, Run, _}) ->
    io:format("  ~-44s ~6b ~13.3f ~13.3f ~10s ~10b~n",
              [filename:basename(File), Lines, Compile, Load, run_text(Run), BeamSize]).

run_text(none) -> "-";
run_text({ok, Ms}) -> lists:flatten(io_lib:format("~.3f", [Ms])).

print_total(Rows) ->
    Ok = [R || R <- Rows, element(2, R) =/= error],
    Compile = lists:sum([element(4, R) || R <- Ok]),
    Load = lists:sum([element(5, R) || R <- Ok]),
    Run = lists:sum([Ms || {_, _, _, _, _, {ok, Ms}, _} <- Ok]),
    Beam = lists:sum([element(3, R) || R <- Ok]),
    io:format("  ~-44s ~6s ~13.3f ~13.3f ~10.3f ~10b~n",
              ["TOTAL (" ++ integer_to_list(length(Ok)) ++ " modules)", "", Compile, Load, Run, Beam]).
ERL

if [ "$have_erl" -eq 1 ]; then
    erlc -o "$scratch" "$bench_erl" >/dev/null 2>&1 || have_erl=0
fi

# comptime_modules <dir> [subdir…]: every `.erl` the build left behind, one per
# line. A missing directory is not an error — a project with no template and no
# decorator writes neither — so `find`'s status is dropped deliberately.
comptime_modules() {
    local dir="$1"; shift
    local sub
    for sub in "$@"; do
        find "$dir/.botopinkbuild/tmp/$sub" -maxdepth 1 -name '*.erl' 2>/dev/null || true
    done | sort
}

# in_node <label> <project-dir>: the E-2 table over every module the build left
# behind under that project's `.botopinkbuild/tmp/`.
in_node() {
    local label="$1" dir="$2"
    local files=()
    while IFS= read -r f; do files+=("$f"); done < <(comptime_modules "$dir" template decorator)
    if [ "${#files[@]}" -eq 0 ]; then
        printf '\nin-node split — %s: no comptime module was written\n' "$label"
        return
    fi
    if [ "$have_erl" -eq 0 ]; then
        printf '\nin-node split — %s: erl/erlc unavailable, skipped (%d modules on disk)\n' \
               "$label" "${#files[@]}"
        return
    fi
    printf '\nin-node split — %s (%d modules, %s reps each, after a warm-up)\n\n' \
           "$label" "${#files[@]}" "$reps"
    printf '  %-44s %6s %13s %13s %10s %10s\n' \
           "module" "lines" "compile:file" "load_binary" "main()" ".beam B"
    erl -noshell -pa "$scratch" -run bp_comptime_bench main "$reps" "${files[@]}"
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
    printf '  %5s %14s %9s %12s %12s\n' "N" "build (ms)" "modules" ".erl bytes" "ms/eval"
    prev_n=""; prev_ms=""; last_dir=""
    IFS=',' read -r -a n_list <<< "$ns"
    for n in "${n_list[@]}"; do
        n="$(echo "$n" | tr -d '[:space:]')"
        [ -n "$n" ] || continue
        dir="$scratch/gen-$n"
        gen_project "$dir" "$n"
        ms="$(build_min "$dir")" || { status=1; printf '  %5s %14s\n' "$n" "BUILD FAILED"; continue; }
        mods=$(comptime_modules "$dir" template decorator | grep -c . || true)
        bytes=$(comptime_modules "$dir" template decorator | xargs -r stat -c '%s' \
                | awk '{s += $1} END {print s + 0}')
        slope="—"
        if [ -n "$prev_n" ] && [ "$n" -gt "$prev_n" ]; then
            slope=$(awk -v a="$prev_ms" -v b="$ms" -v c="$prev_n" -v d="$n" 'BEGIN {printf "%.1f", (b - a) / (d - c)}')
        fi
        printf '  %5s %14s %9s %12s %12s\n' "$n" "$ms" "$mods" "$bytes" "$slope"
        prev_n="$n"; prev_ms="$ms"; last_dir="$dir"
    done
    [ -n "$last_dir" ] && in_node "generated N=$prev_n" "$last_dir"
fi

# ── a real project ────────────────────────────────────────────────────────────
#
# Copied out of its repository first: a build writes `.botopinkbuild/` and `out/`,
# and this script writes nothing inside a checkout.

for p in ${projects+"${projects[@]}"}; do
    [ -d "$p" ] || { echo "comptime_bench: --project $p is not a directory" >&2; status=1; continue; }
    name="$(basename "$p")"
    dir="$scratch/$name"
    cp -r "$p" "$dir"
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
    in_node "$name" "$dir"
done

exit "$status"
