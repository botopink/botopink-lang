#!/usr/bin/env bash
# snap_audit.sh — meta-audit of every *.snap.md in the workspace.
#
# Authored by tasks/v0.beta.20/specs/snap-audit.md. Pure shell + awk;
# read-only. Writes its reports under build/snap-audit/<mode>.tsv
# (relative to repository/botopink-lang/).
#
# Usage:
#   scripts/snap_audit.sh --mode={runlog,legacy,values,coverage}
#
# Modes:
#   runlog    Classify every codegen snap as (a) silent / (b) observable /
#             (c) deferred-observable; capture whether the section
#             exists + whether its content is empty.
#             Columns: backend\tlabel\trunlog_state\tpath
#               runlog_state ∈ {nonempty,empty,missing}
#               label        ∈ {a,b,c}
#               backend      ∈ {node,erlang,beam,wasm,errors}
#   legacy    Grep every snap's SOURCE CODE block for legacy surface
#             listed in §F2 of the spec. Columns: surface\tpath\tline
#   values    Dump (suite, backend, source-hash, runlog-text) for the
#             non-empty (b) codegen snaps so F3 can cross-check values.
#             Columns: backend\tsource_sha1\tpath\trunlog_text(escaped)
#   coverage  Pivot of `runlog` by backend × label × runlog_state.
#             Prints the table to stdout AND saves a copy to coverage.tsv.
#
# Exit codes:
#   0  reports written
#   1  argument error / unknown mode
#   2  IO error (snapshots dir missing, write failure)

set -euo pipefail

usage() {
    cat >&2 <<'USAGE'
usage: scripts/snap_audit.sh --mode={runlog,legacy,values,coverage}

Reports land under repository/botopink-lang/build/snap-audit/<mode>.tsv.
USAGE
}

if [ "$#" -ne 1 ]; then
    usage
    exit 1
fi

mode=""
case "$1" in
    --mode=runlog)   mode=runlog ;;
    --mode=legacy)   mode=legacy ;;
    --mode=values)   mode=values ;;
    --mode=coverage) mode=coverage ;;
    -h|--help)       usage; exit 0 ;;
    *)               usage; exit 1 ;;
esac

# Resolve the bot-lang root regardless of where the script is invoked from.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
botlang_root="$(cd "$script_dir/.." && pwd)"
codegen_dir="$botlang_root/modules/compiler-core/snapshots/codegen"
parser_dir="$botlang_root/modules/compiler-core/snapshots/parser"
comptime_dir="$botlang_root/modules/compiler-core/snapshots/comptime"
lsp_dir="$botlang_root/modules/language-server/snapshots/lsp"

if [ ! -d "$codegen_dir" ]; then
    echo "snap_audit: codegen snapshots dir not found at $codegen_dir" >&2
    exit 2
fi

out_dir="$botlang_root/build/snap-audit"
mkdir -p "$out_dir"

# Backend derived from the path component immediately after .../codegen/.
# The codegen layout is codegen/<backend>/<lang>/<slug>.snap.md, plus a
# codegen/errors/<backend>/<lang>/<slug>.snap.md tree. The "errors" leg
# never carries a RUN LOG by contract — surface it under its own
# backend label so the coverage pivot stays meaningful.
backendOf() {
    local p="$1"
    case "$p" in
        */codegen/errors/*) echo errors ;;
        */codegen/node/*)   echo node ;;
        */codegen/erlang/*) echo erlang ;;
        */codegen/beam/*)   echo beam ;;
        */codegen/wasm/*)   echo wasm ;;
        *)                  echo unknown ;;
    esac
}

# Classify a codegen snap by its SOURCE CODE block + its RUN LOG section.
# Emits one line: `<label>\t<runlog_state>` where
#   label        — a (silent) / b (observable, has fn main()) / c (deferred — has @print but no fn main())
#   runlog_state — nonempty / empty / missing
classifyCodegen() {
    awk '
        BEGIN { in_src=0; in_run=0; saw_run=0; src=""; run=""; has_main=0; has_print=0 }
        /^----- SOURCE CODE/  { in_src=0; section="src"; next }
        /^----- RUN LOG -----/ { in_run=0; section="run"; saw_run=1; next }
        /^----- /              { section="other"; next }
        /^```botopink/         { if (section=="src") in_src=1; next }
        /^```logs/             { if (section=="run") in_run=1; next }
        /^```/                 { in_src=0; in_run=0; next }
        in_src                 { src = src $0 "\n" }
        in_run                 { run = run $0 "\n" }
        END {
            if (src ~ /\<fn[[:space:]]+main[[:space:]]*\(/) has_main=1
            if (src ~ /@print|@assert|@panic/)              has_print=1
            label = (has_print && has_main) ? "b" : (has_print ? "c" : "a")
            if (!saw_run)         state = "missing"
            else if (run == "")   state = "empty"
            else                  state = "nonempty"
            print label "\t" state
        }
    ' "$1"
}

# Pull the SOURCE CODE block of a snap (any suite) into stdout, stripped
# of the fence lines.
extractSource() {
    awk '
        BEGIN { in_src=0 }
        /^----- SOURCE CODE/    { section="src"; next }
        /^----- /               { section="other"; in_src=0; next }
        /^```botopink/          { if (section=="src") { in_src=1; next } }
        /^```/                  { if (in_src) { in_src=0; next } }
        in_src                  { print }
    ' "$1"
}

# Pull the RUN LOG block content (whatever's inside ```logs ... ```).
extractRunLog() {
    awk '
        BEGIN { in_run=0 }
        /^----- RUN LOG -----/  { section="run"; next }
        /^----- /               { section="other"; in_run=0; next }
        /^```logs/              { if (section=="run") { in_run=1; next } }
        /^```/                  { if (in_run) { in_run=0; next } }
        in_run                  { print }
    ' "$1"
}

case "$mode" in
    runlog)
        # ---- F0.1 --mode=runlog
        out="$out_dir/runlog.tsv"
        : > "$out"
        printf 'backend\tlabel\trunlog_state\tpath\n' >> "$out"
        find "$codegen_dir" -name '*.snap.md' -print | sort | while IFS= read -r p; do
            backend="$(backendOf "$p")"
            cls="$(classifyCodegen "$p")"
            rel="${p#$botlang_root/}"
            printf '%s\t%s\t%s\n' "$backend" "$cls" "$rel" >> "$out"
        done
        printf 'wrote %s (%d rows)\n' "$out" "$(($(wc -l < "$out") - 1))"
        ;;

    legacy)
        # ---- F0.1 --mode=legacy
        out="$out_dir/legacy.tsv"
        : > "$out"
        printf 'surface\tpath\tline\n' >> "$out"
        # Each row: surface_key + extended-regex applied to SOURCE blocks
        # only (we extract first to avoid hitting the emitted-code
        # sections where these literals legitimately appear). Uses
        # `grep -nE` instead of awk because awk's `\*` / `\[` get
        # un-escaped when passed via `-v`, producing nonsense regexes.
        scan() {
            local key="$1" pattern="$2" root="$3"
            [ -d "$root" ] || return 0
            find "$root" -name '*.snap.md' -print | sort | while IFS= read -r p; do
                rel="${p#$botlang_root/}"
                # grep -nE emits `<line>:<text>`; we keep only the line
                # number and drop the body. `|| true` so a zero-hit
                # file doesn't trip set -e.
                extractSource "$p" | grep -nE "$pattern" 2>/dev/null | \
                    awk -F: -v key="$key" -v pth="$rel" '{ printf "%s\t%s\t%s\n", key, pth, $1 }' \
                    >> "$out" || true
            done
        }
        # Surface list mirrors §F2 of the spec.
        # The grep ERE escapes are literal here — they survive the shell
        # quoting because every regex is in single quotes.
        for suite in codegen parser comptime lsp; do
            case "$suite" in
                codegen)  root="$codegen_dir" ;;
                parser)   root="$parser_dir" ;;
                comptime) root="$comptime_dir" ;;
                lsp)      root="$lsp_dir" ;;
            esac
            # `*fn ` v19 §S removed. Anchored at BoL or whitespace so we
            # do not match identifiers like `defaultFn` that legitimately
            # contain the substring.
            scan "star-fn"            '(^|[[:space:]])\*fn[[:space:]]'        "$root"
            # Legacy `#\[@External\.target("…")]` form retired by prim-op-annotation.
            scan "external-legacy"    '#\[@external\([a-zA-Z_]+,'             "$root"
            # `@[name]` outside `#[…]` — the deprecated annotation form.
            # Restrict to forms that look like annotations (lowercase
            # letter immediately after `[`, followed by `]` or `(`).
            scan "at-bracket-annot"   '@\[[a-z][a-zA-Z0-9_]*[](]'             "$root"
            # `when($argc == N)` literal retired by prim-op-extension when-argc-removal.
            scan "when-argc"          'when\(\$argc[[:space:]]*=='            "$root"
            # `string.length()` / `value:length()` template footguns from memory.
            scan "string-dot-length"  'string\.length\(\)'                    "$root"
            scan "value-colon-length" 'value:length\(\)'                      "$root"
        done
        printf 'wrote %s (%d rows)\n' "$out" "$(($(wc -l < "$out") - 1))"
        ;;

    values)
        # ---- F0.1 --mode=values
        # Only for (b) codegen snaps with non-empty RUN LOG: emit a row
        # with the source SHA-1 (so duplicate fixtures collapse) and
        # the runlog text base64-encoded (so tabs/newlines survive a
        # TSV column intact).
        out="$out_dir/values.tsv"
        : > "$out"
        printf 'backend\tsource_sha1\tpath\trunlog_b64\n' >> "$out"
        find "$codegen_dir" -name '*.snap.md' -print | sort | while IFS= read -r p; do
            backend="$(backendOf "$p")"
            [ "$backend" = "errors" ] && continue
            cls="$(classifyCodegen "$p")"
            label="${cls%%	*}"
            state="${cls##*	}"
            [ "$label" = "b" ] || continue
            [ "$state" = "nonempty" ] || continue
            rel="${p#$botlang_root/}"
            src_sha="$(extractSource "$p" | sha1sum | awk '{print $1}')"
            runlog_b64="$(extractRunLog "$p" | base64 -w0)"
            printf '%s\t%s\t%s\t%s\n' "$backend" "$src_sha" "$rel" "$runlog_b64" >> "$out"
        done
        printf 'wrote %s (%d rows)\n' "$out" "$(($(wc -l < "$out") - 1))"
        ;;

    coverage)
        # ---- F0.1 --mode=coverage
        # Builds on --mode=runlog. Re-runs the classifier to stay
        # stateless (the user can call --mode=coverage directly without
        # having run --mode=runlog first).
        out="$out_dir/coverage.tsv"
        tmp="$(mktemp)"
        trap 'rm -f "$tmp"' EXIT
        find "$codegen_dir" -name '*.snap.md' -print | sort | while IFS= read -r p; do
            backend="$(backendOf "$p")"
            cls="$(classifyCodegen "$p")"
            printf '%s\t%s\n' "$backend" "$cls" >> "$tmp"
        done
        # Pivot in awk: counts by (backend, label, state).
        awk -F'\t' '
            { count[$1 "\t" $2 "\t" $3]++; totals[$1]++ }
            END {
                printf "backend\tlabel\tstate\tcount\tpct_of_backend\n"
                for (k in count) {
                    split(k, a, "\t")
                    printf "%s\t%s\t%s\t%d\t%.1f%%\n", a[1], a[2], a[3], count[k], (count[k]/totals[a[1]])*100
                }
            }
        ' "$tmp" | sort > "$out"
        # Pretty-print to stdout: backend × label matrix.
        printf '\n# coverage pivot (backend × label):\n'
        awk -F'\t' '
            NR==1 { next }
            { lbl=$2; state=$3; key=$1 "\t" lbl "/" state; counts[key]+=$4; totals[$1]+=$4; labels[lbl "/" state]=1; backends[$1]=1 }
            END {
                printf "%-10s", "backend"
                n=0; for (l in labels) { ord[++n]=l }
                # Stable order
                ord_arr[1]="a/missing"; ord_arr[2]="a/empty"; ord_arr[3]="a/nonempty"
                ord_arr[4]="b/missing"; ord_arr[5]="b/empty"; ord_arr[6]="b/nonempty"
                ord_arr[7]="c/missing"; ord_arr[8]="c/empty"; ord_arr[9]="c/nonempty"
                for (i=1;i<=9;i++) printf "  %-12s", ord_arr[i]
                printf "  %-6s\n", "total"
                for (b in backends) {
                    printf "%-10s", b
                    for (i=1;i<=9;i++) {
                        k=b "\t" ord_arr[i]
                        c=(k in counts)?counts[k]:0
                        printf "  %-12d", c
                    }
                    printf "  %-6d\n", totals[b]
                }
            }
        ' "$out"
        printf '\nwrote %s\n' "$out"
        ;;
esac
