#!/usr/bin/env bash
# format-staged.sh — `botopink format` applied to the commit (decision 524).
#
# The formatter is applied, never checked: no stage of the gate fails on a file
# that is not canonical. The commit hook formats the version of each source
# file that ENTERS the commit — the staged blob, never the working tree — and
# writes the result back into the index, so the commit records it:
#
#   1. the staged source files (`.bp`, `.bpp`, `.botopink`; added,
#      copied, modified or renamed — a deletion and an unmerged path have
#      nothing to format) are checked out of the index into a scratch tree
#      with `git checkout-index --prefix`, together with the
#      `snapshot/output/` files of every directory above them, so the walk
#      sees what it sees in the checkout;
#   2. `botopink format .` walks the scratch tree — the same walk as in the
#      checkout, so the structural exemptions hold (decision 67: a hidden
#      directory, `node_modules`, a conformance cell's module whose
#      `snapshot/output/<module>.snap` holds a `refused` record);
#   3. each staged file the formatter changed is written as a blob
#      (`git hash-object -w`) and put in the index in place of the staged one
#      (`git update-index --cacheinfo`, the staged mode kept) — `GIT_INDEX_FILE`
#      is the committing index, `git commit -a` included; under `git commit
#      <path>` the real index git writes beside it (`index.lock`) takes it too;
#   4. the working-tree file takes the formatted text only when it still holds
#      exactly the staged text. A file with unstaged changes keeps them, untouched:
#      the commit records the formatted staged version, and the unstaged hunks
#      wait for the commit that stages them.
#
# A file the formatter cannot parse is committed as written, its diagnostic
# printed — the hook never fails on formatting; a parse error is the gate's to
# report. The formatter is this checkout's own (`zig build -Doptimize=ReleaseSafe`,
# the gate's stage 2 build, which the gate then finds cached), so a commit that
# changes the printer formats its own sources with the printer it commits.
#
# Sourced by `scripts/git-hooks/pre-commit`; `formatStaged` runs before the gate.

formatStaged() {
    local root bin scratch list dirs out esc status=0
    root=$(git rev-parse --show-toplevel)

    list=$(git diff --cached --name-only --diff-filter=ACMR -- '*.bp' '*.bpp' '*.botopink')
    [ -n "$list" ] || return 0

    echo "── botopink format: the staged source files (decision 524) ──"
    # The build sees none of the committing repository's git environment.
    # shellcheck disable=SC2046
    if ! (cd "$root" && unset $(git rev-parse --local-env-vars) && zig build -Doptimize=ReleaseSafe); then
        echo "format: zig build failed — the staged files are committed as written; the gate reports the build" >&2
        return 0
    fi
    bin="$root/zig-out/bin/botopink"
    [ -x "$bin" ] || bin="$bin.exe"

    scratch=$(mktemp -d "${TMPDIR:-/tmp}/bp-format-staged.XXXXXX")

    # The staged files, and the snapshot/output/ files of every directory above
    # them (the walk reads a cell's refusal there).
    dirs=$(printf '%s\n' "$list" | while IFS= read -r f; do
        d=$(dirname "$f")
        while :; do
            if [ "$d" = . ]; then printf 'snapshot/output\n'; break; fi
            printf '%s/snapshot/output\n' "$d"
            d=$(dirname "$d")
        done
    done | sort -u)
    if ! {
        printf '%s\n' "$list"
        printf '%s\n' "$dirs" | while IFS= read -r d; do git -C "$root" ls-files -- "$d"; done
    } | sort -u | (cd "$root" && git checkout-index --prefix="$scratch/" --stdin); then
        echo "format: could not check the staged files out of the index — committed as written" >&2
        rm -rf "$scratch"
        return 0
    fi

    # Every `Unchanged` / `Formatted` line dropped; what stays is a file that
    # could not be formatted, with its located diagnostic.
    out=$(cd "$scratch" && "$bin" format . 2>&1) || status=$?
    if [ "$status" -ne 0 ]; then
        esc="$(printf '\033')"
        printf '%s\n' "$out" | grep -vE "^[[:space:]]*(${esc}\[[0-9;]*m)?(Unchanged|Formatted)" >&2 || true
        echo "format: the files named above are committed as written" >&2
    fi

    local f mode old new partial_index="" changed=0
    case "${GIT_INDEX_FILE:-}" in
        */next-index-*.lock)
            partial_index="$(dirname "$GIT_INDEX_FILE")/index.lock"
            [ -f "$partial_index" ] || partial_index="" ;;
    esac
    while IFS= read -r f; do
        [ -n "$f" ] || continue
        read -r mode old _ < <(git -C "$root" ls-files -s -- "$f") || continue
        case "$mode" in 100644|100755) ;; *) continue ;; esac
        [ -f "$scratch/$f" ] || continue
        new=$(git -C "$root" hash-object -w --no-filters -- "$scratch/$f")
        [ "$new" != "$old" ] || continue
        git -C "$root" update-index --cacheinfo "$mode,$new,$f"
        # `git commit <path>` commits a temporary index (`next-index-*.lock`) and
        # writes the paths into the real one (`index.lock`) beside it: that entry
        # takes the formatted blob too, so the index matches what is committed.
        if [ -n "$partial_index" ] &&
            [ "$(GIT_INDEX_FILE="$partial_index" git -C "$root" ls-files -s -- "$f" | cut -d' ' -f2)" = "$old" ]; then
            GIT_INDEX_FILE="$partial_index" git -C "$root" update-index --cacheinfo "$mode,$new,$f"
        fi
        if [ -f "$root/$f" ] && [ "$(git -C "$root" hash-object --no-filters -- "$root/$f")" = "$old" ]; then
            cp "$scratch/$f" "$root/$f"
            echo "  formatted $f"
        else
            echo "  formatted $f (in the index; its unstaged changes stay in the working tree)"
        fi
        changed=$((changed + 1))
    done <<<"$list"
    rm -rf "$scratch"
    [ "$changed" -eq 0 ] || echo "format: $changed staged file(s) formatted into the commit"
    return 0
}
