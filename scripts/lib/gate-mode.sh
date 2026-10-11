#!/usr/bin/env bash
# gate-mode.sh — which gate a checkout runs, and what the step gate reaches
# (decision 460 of 1.0.12-beta; front 144 B-29 step G).
#
# Sourced by scripts/gate.sh. Two questions, each answered from the repository
# alone — no flag, no variable, no file a commit sets can answer either:
#
#   gate_mode <branch>   `step` when the branch is `front/*`, `full` otherwise
#                        (`feat`, `main`, a detached HEAD — an empty branch —
#                        and every other branch). The coordinator's full gate of
#                        a front is the same script on the main checkout at a
#                        detached HEAD (scripts/AGENTS.md § Step gate and full
#                        gate).
#   gate_reach <partition> <file>…
#                        what the files reach, from the backend partition of
#                        decision 249 (modules/compiler-core/src/codegen/
#                        backend-partition.txt). Sets
#                          reach_all      1 when every cell runs, 0 when a subset
#                          reach_targets  the targets (canonical order) of the
#                                         subset, "" when it reaches no cell
#                          reach_why      the line `gate.sh` prints
#
# A file reaches ONE backend when the partition lists it under that target; it
# reaches NOTHING beyond the stages that always run (formatting, build, `zig
# build test`, test-cli, test-docs, tsc-check, test-web) when it is a `*.md`
# outside tests/ and libs/ — the result store's source set leaves every `*.md`
# out of every key (modules/source-stamp/src/root.zig), so no cell reads one;
# every other file — the dispatcher, the checker, comptime, std (libs/), the
# CLI, the runners, build.zig, a snapshot, a test cell, the partition itself, a
# file the partition does not list, a path outside the partition's listing —
# reaches every cell. An empty file list (nothing to measure) reaches every cell.
# The doubt always goes to the wider run.

ALL_TARGETS_ORDER="commonJS erlang wasm beam"

gate_mode() { # <branch> — "" for a detached HEAD
    case "$1" in
        front/*) echo step ;;
        *) echo full ;;
    esac
}

gate_reach() { # <partition file> <file>…
    # No associative arrays: the gate also runs under the macOS runner's bash 3.2.
    local partition="$1" f t kind p dispatcher hit=" " docs_only=1
    shift
    reach_all=0
    reach_targets=""
    reach_why=""
    dispatcher="$(awk '$1 == "dispatcher" { print $2 }' "$partition")"
    if [ "$#" -eq 0 ]; then
        reach_all=1
        reach_why="no changed file to measure"
        return 0
    fi
    for f in "$@"; do
        [ -n "$f" ] || continue
        case "$f" in
            tests/*|libs/*) ;;
            *.md) continue ;;
        esac
        docs_only=0
        t=""
        if [ "$f" != "$dispatcher" ]; then
            t="$(awk -v f="$f" '$1 ~ /^(commonJS|erlang|wasm|beam)$/ && $2 == f { print $1; exit }' "$partition")"
        fi
        if [ -z "$t" ]; then
            reach_all=1
            reach_why="shared file: $f"
            if [ "$f" = "$dispatcher" ]; then reach_why="$reach_why (the dispatcher)"; fi
            return 0
        fi
        case "$hit" in *" $t "*) ;; *) hit="$hit$t " ;; esac
    done
    for t in $ALL_TARGETS_ORDER; do
        case "$hit" in *" $t "*) reach_targets="${reach_targets:+$reach_targets,}$t" ;; esac
    done
    if [ "$docs_only" -eq 1 ]; then
        reach_why="documentation only (no cell reads a *.md)"
    else
        reach_why="reaches ${reach_targets//,/, } only"
    fi
}

# Run directly: `scripts/lib/gate-mode.sh <branch> <file>…` prints the mode and the
# reach for a branch and a file list — the way to see what a change would run.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    set -euo pipefail
    here="$(cd "$(dirname "$0")" && pwd)"
    branch="${1:-}"
    shift || true
    mode="$(gate_mode "$branch")"
    gate_reach "$here/../../modules/compiler-core/src/codegen/backend-partition.txt" "$@"
    echo "mode=$mode reach_all=$reach_all targets=${reach_targets:-none} why=$reach_why"
fi
